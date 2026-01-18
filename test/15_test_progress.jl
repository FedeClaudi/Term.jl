using Term.Progress
import Term.Progress: AbstractColumn, getjob, get_columns, jobcolor
import Term: install_term_logger, uninstall_term_logger, str_trunc
import Term.Progress:
    CompletedColumn, SeparatorColumn, ProgressColumn, DescriptionColumn, TextColumn, SpinnerColumn, ETAColumn

using ProgressLogging
import ProgressLogging.Logging.global_logger

using UUIDs

@testset "\e[34mProgress - jobs" begin
    pbar = ProgressBar()

    io = PipeBuffer()
    show(io, MIME("text/plain"), pbar)  # coverage
    @test startswith(read(io, String), "Progress bar")

    j1 = addjob!(pbar; description = "test", N = 10)
    @test render(j1) isa String  # coverage
    @test jobcolor(j1) == "(209, 16, 112)"

    @test j1.id == 1
    @test j1.N == 10
    @test j1.i == 0
    @test j1.description == "test"
    @test j1.started
    @test j1.columns isa Vector{AbstractColumn}

    update!(j1)
    @test j1.i == 1
    update!(j1; i = 10)
    @test j1.i == 10 # ? In what situation would we want to += i?

    @test getjob(pbar, j1.id).id == j1.id

    removejob!(pbar, j1)
    @test length(pbar.jobs) == 0
end

@testset "\e[34mProgress basic" begin
    @test_nothrow begin
        pbar = ProgressBar()
        with(pbar) do
            job = addjob!(pbar; N = 10)
            for i in 1:10
                update!(job)
                sleep(0.001)
            end
        end
    end

    @test_nothrow begin
        pbar2 = ProgressBar(; transient = true)
        with(pbar2) do
            job = addjob!(pbar2; N = 10)
            job2 = nothing
            for i in 1:10
                i == 50 && (job2 = addjob!(pbar2; N = 10))
                i ≥ 50 && update!(job2)
                i == 75 && removejob!(pbar2, job2)

                update!(job)
                sleep(0.001)
            end
        end
    end

    @test_nothrow begin
        @track for i in 1:10
            sleep(0.001)
        end
    end
end

@testset "\e[34mProgress columns" begin
    for (i, colinfo) in enumerate((:minimal, :default, :spinner, :detailed))
        pbar = ProgressBar(; columns = colinfo)
        @test pbar.columns == get_columns(colinfo)
        @test pbar.columns isa Vector{DataType}

        job = addjob!(pbar; N = colinfo == :spinner ? nothing : 10)
        @test job.columns isa Vector{AbstractColumn}

        with(pbar) do
            for i in 1:10
                update!(job)
                sleep(0.01)
            end
        end

        start!(pbar)
        (!IS_WIN && colinfo ∈ [:spinner]) &&
            @compare_to_string render(job) "pbar_cols_style_$i"
    end

    mycols =
        [DescriptionColumn, CompletedColumn, SeparatorColumn, ProgressColumn, TextColumn]
    colkwargs = Dict(
        :DescriptionColumn => Dict(:style => "red"),
        :TextColumn => Dict(:text => "test"),
    )
    pbar = ProgressBar(; columns = mycols, columns_kwargs = colkwargs)
    job = addjob!(pbar; N = 10)
    @test job.columns[1].segments[1].text == "\e[31mRunning...\e[39m"
end

@testset "Progress customization" begin
    pbar = ProgressBar(;
        expand = true,
        columns = :detailed,
        colors = "#ffffff",
        columns_kwargs = Dict(
            :ProgressColumn => Dict(:completed_char => '█', :remaining_char => '░'),
        ),
    )
    job = addjob!(pbar; N = 100, description = "Test")

    job2 = addjob!(
        pbar;
        N = 100,
        description = "Test2",
        columns_kwargs = Dict(
            :ProgressColumn => Dict(:completed_char => 'x', :remaining_char => '_'),
        ),
    )

    with(pbar) do
        for i in 1:100
            update!(job)
            update!(job2)
            sleep(0.01)
            i == 45 && break
        end
    end

    start!(pbar)  # re-activate
    IS_WIN || @compare_to_string render(pbar) "pbar_customization"
end

using Test
using Term
using Term.Progress
import Term.Progress:
    CompletedColumn, SeparatorColumn, ProgressColumn, DescriptionColumn, TextColumn, SpinnerColumn, ETAColumn

@testset "\e[34mProgress swapjob!()" begin

    # one bar.
    @test_nowarn let p = ProgressBar(; title = "swapjob!(): basic")
        j = addjob!(p; description="No N bound...")
        with(p) do
            for i in 1:100
                if i == 50
                    j = swapjob!(p, j; N=100, description = "N bounded",
                                 columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                            SeparatorColumn, ProgressColumn, SeparatorColumn, SpinnerColumn])
                end
                update!(j; i=i)
                sleep(0.05)
            end
        end
    end

    # three bars, with state inheritance.
    @test_nowarn let p = ProgressBar(; title = "swapjob!(): multiple bars")
        j1 = addjob!(p; description="[1]: No N bound...")
        j2 = addjob!(p; description="[2]: No N bound...")
        j3 = addjob!(p; description="[3]: No N bound...")
        with(p) do
            for i in 1:300
                if i == 50
                    j1 = swapjob!(p, j1; N=300, description = "[1]: N bounded", inherit = true,
                                  columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                             SeparatorColumn, ProgressColumn, SeparatorColumn, SpinnerColumn])
                end
                if i == 150
                    j2 = swapjob!(p, j2; N=300, description = "[2]: N bounded", inherit = true,
                                  columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                             SeparatorColumn, ProgressColumn, SeparatorColumn,
                                             ETAColumn, SpinnerColumn])
                end
                if i == 200
                    j3 = swapjob!(p, j3; N=300, description = "[3]: N bounded", inherit = true,
                                  columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                             SeparatorColumn, ProgressColumn, SeparatorColumn, SpinnerColumn])
                end
                update!.([j1, j2, j3])
                sleep(0.02)
            end
        end
    end

    # three bars, with state inheritance, mixed ID types, lookup by ID,
    # addition and removal of ProgressColumn when N is set or unset
    let p = ProgressBar(; title = "swapjob!(): lookup by ID")
        j1 = addjob!(p; description="[1]: No N bound...")
        j2 = addjob!(p; description="[2]: No N bound...", id = uuid1())
        j3 = addjob!(p; description="[3]: No N bound...", id = uuid7())
        with(p) do
            for i in 1:300
                if i == 50
                    j1 = swapjob!(p, j1.id; N=300, description = "[1]: N bounded", inherit = true,
                                  columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                             SeparatorColumn, ProgressColumn, SeparatorColumn, SpinnerColumn])
                    @test ProgressColumn in typeof.(j1.columns)
                    @test !(ProgressColumn in typeof.(j2.columns))
                    @test !(ProgressColumn in typeof.(j3.columns))
                end
                if i == 150
                    j2 = swapjob!(p, j2.id; N=300, description = "[2]: N bounded", inherit = true,
                                  columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                             SeparatorColumn, ProgressColumn, SeparatorColumn,
                                             ETAColumn, SpinnerColumn])
                    @test ProgressColumn in typeof.(j1.columns)
                    @test ProgressColumn in typeof.(j2.columns)
                    @test !(ProgressColumn in typeof.(j3.columns))
                end
                if i == 200
                    j3 = swapjob!(p, j3.id; N=300, description = "[3]: N bounded", inherit = true,
                                  columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                             SeparatorColumn, ProgressColumn, SeparatorColumn, SpinnerColumn])
                    @test ProgressColumn in typeof.(j1.columns)
                    @test ProgressColumn in typeof.(j2.columns)
                    @test ProgressColumn in typeof.(j3.columns)
                end
                if i == 250
                    j1 = swapjob!(p, j1.id, description = "[1]: Lost bound!", N=nothing, inherit = true)
                    @test !(ProgressColumn in typeof.(j1.columns))
                    @test ProgressColumn in typeof.(j2.columns)
                    @test ProgressColumn in typeof.(j3.columns)
                end
                update!.([j1, j2, j3])
                sleep(0.02)
            end
        end
    end

    # three bars, second is transient and finishes early.
    @test_nothrow let p = ProgressBar(; title = "swapjob!(): Test early-finishing bar with inherited transience")
        j1 = addjob!(p; description="[1]: No N bound...")
        j2 = addjob!(p; description="[2]: No N bound...", id = uuid1(), transient = true)
        j3 = addjob!(p; description="[3]: No N bound...", id = uuid7())
        with(p) do
            for i in 1:300
                if i == 50
                    j1 = swapjob!(p, j1.id; N=300, description = "[1]: N bounded", inherit = true,
                                  columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                             SeparatorColumn, ProgressColumn, SeparatorColumn, SpinnerColumn])
                end
                if i == 150
                    j2 = swapjob!(p, j2.id; N=200, description = "[2]: N bounded", inherit = true,
                                  columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                             SeparatorColumn, ProgressColumn, SeparatorColumn,
                                             ETAColumn, SpinnerColumn])
                end
                if i == 200
                    j3 = swapjob!(p, j3.id; N=300, description = "[3]: N bounded", inherit = true,
                                  columns = [DescriptionColumn, SeparatorColumn, CompletedColumn,
                                             SeparatorColumn, ProgressColumn, SeparatorColumn, SpinnerColumn])
                end
                if i == 250
                    j1 = swapjob!(p, j1.id, description = "[1]: Lost bound!", N=nothing, inherit = true)
                end
                update!.([j1, j2, j3])
                sleep(0.02)
            end
        end
    end

    # see if we can get an argument error out
    let p = ProgressBar(; title = "swapjob!(): throw error on bad ID")
        u = uuid1()
        v = uuid1()
        j = addjob!(p; id = u)
        u == v && error("ffs hahahahahahahahahaha")
        with(p) do
            update!(j)
            @test_nowarn begin
                j = swapjob!(p, u; N = 1000)
            end
            update!(j)
            @test_throws ArgumentError begin
                j = swapjob!(p, v; N = 2000)
            end
            update!(j)
        end
    end
end


@testset "\e[34mProgress foreachprogress" begin
    @test_nowarn redirect_stdout(Base.DevNull()) do
        Term.Progress.foreachprogress(1:10) do i
            sleep(0.01)
        end
    end
end
@testset "\e[34mProgress ProgressLogging" begin
    install_term_logger()

    @progress "loop" for j in 1:10
        sleep(0.01)
    end
end
@testset "\e[34mProgress ProgressLogging custom io" begin
    buffer = IOBuffer()
    io = IOContext(buffer, :displaysize => (30, 1000), :color => false)

    logger = Term.Logs.TermLogger(io, Term.TERM_THEME[])
    global_logger(logger)

    @info "logger message"
    out = String(take!(buffer))
    @test occursin("logger message", out)

    @progress "loop" for j in 1:10
        sleep(0.1)
    end
    out = String(take!(buffer))
    @test occursin("90%", out) # Check it runs to completion
end
