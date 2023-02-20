using Term.Progress
import Term.Progress: AbstractColumn, getjob, get_columns, jobcolor
import Term: install_term_logger, uninstall_term_logger, str_trunc
import Term.Progress:
    CompletedColumn, SeparatorColumn, ProgressColumn, DescriptionColumn, TextColumn

using ProgressLogging

@testset "\e[34mProgress - jobs" begin
    pbar = ProgressBar()

    io = PipeBuffer()
    show(io, MIME("text/plain"), pbar)  # coverage
    @test startswith(read(io, String), "Progress bar")

    j1 = addjob!(pbar; description = "test", N = 10)
    @test render(j1) isa String  # coverage
    @test jobcolor(j1) == "(190, 35, 112)"

    @test j1.id == 1
    @test j1.N == 10
    @test j1.i == 1
    @test j1.description == "test"
    @test j1.started
    @test j1.columns isa Vector{AbstractColumn}

    update!(j1)
    @test j1.i == 2
    update!(j1; i = 10)
    @test j1.i == 12

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
        (IS_WIN || colinfo ∉ (:detailed, :spinner)) ||
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

@testset "\e[34mProgress foreachprogress" begin
    @test_nowarn redirect_stdout(Base.DevNull()) do
        Term.Progress.foreachprogress(1:10) do i
            sleep(0.01)
        end
    end
end
# @testset "\e[34mProgress ProgressLogging" begin
#     install_term_logger()

#     @test_nothrow begin
#         @progress "inner... $i" for j in  1:10
#             sleep(0.01)
#         end
#     end
# end
