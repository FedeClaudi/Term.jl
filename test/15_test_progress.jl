using Term.progress
import Term.progress: AbstractColumn, getjob, get_columns
using ProgressLogging

@testset "\e[34mProgress - jobs" begin
    pbar = ProgressBar()

    j1 = addjob!(pbar; description="test", N=100)

    @test j1.id == 1
    @test j1.N == 100
    @test j1.i == 1
    @test j1.description == "test"
    @test j1.started == true
    @test typeof(j1.columns) == Vector{AbstractColumn}

    update!(j1)
    @test j1.i == 2
    update!(j1; i=10)
    @test j1.i == 10

    @test getjob(pbar, j1.id).id == j1.id

    removejob!(pbar, j1)
    @test length(pbar.jobs) == 0

end

@testset "\e[34mProgress basic" begin
    @test_nothrow begin
        pbar = ProgressBar()
        with(pbar) do 
            job = addjob!(pbar; N=100)
            for i in 1:100
                update!(job)
                sleep(.001)
            end
        end
    end

    @test_nothrow begin
        pbar2 = ProgressBar(; transient=true)
        with(pbar2) do 
            job = addjob!(pbar2; N=100)
            job2 = nothing
            for i in 1:100
                if i == 50
                    job2 = addjob!(pbar2; N=100)
                end

                if i >= 50
                    update!(job2)
                end

                if i == 75
                    removejob!(pbar2, job2)
                end

                update!(job)
                sleep(.001)
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
    for colinfo in (:minimal, :default, :spinner, :detailed)
        pbar = ProgressBar(columns=colinfo)
        @test pbar.columns == get_columns(colinfo)
        @test typeof(pbar.columns) == Vector{DataType}

        job = addjob!(pbar; N= colinfo == :spinner ? nothing : 100)
        @test typeof(job.columns) == Vector{AbstractColumn}

        with(pbar) do
            for i in 1:100
                update!(job)
                sleep(0.01)
            end
        end
    end

    colkwargs = Dict(:DescriptionColumn=>Dict(:style=>"red"))
    pbar = ProgressBar(;columns_kwargs=colkwargs)
    job = addjob!(pbar; N=100)
    @test job.columns[1].segments[1].text == "\e[31mRunning...\e[39m"

end


@testset "\e[34mProgress ProgressLogging" begin
    @test_nothrow begin
        @progress "outer...." for i in 1:6
            @progress "inner... $i" for j in  1:100
                sleep(0.01)
            end
        end
    end
end