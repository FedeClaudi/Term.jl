using Term.progress
import Term.console: clear
import Term.progress: SPINNERS
import Term: tprintln, Panel

function simple(; kwargs...)
    pbar = ProgressBar(; refresh_rate=60, expand=false, width=150, kwargs...)
    j1 = addjob!(pbar; N=100, description="First")

    with(pbar) do
        for i in 1:100
            update!(j1)
            sleep(0.01)
        end
    end
end

function multi_nested()
    pbar = ProgressBar(; refresh_rate=60, expand=false, width=150)
    with(pbar) do
        outer = addjob!(pbar; N=3, description="outer")
        for i in 1:3
            inner = addjob!(pbar, N=100, description="inner $i")
            for j in 1:100
                update!(inner)
                sleep(0.005)
            end

            update!(outer)
            removejob!(pbar, inner)
            sleep(0.02)
        end
    end
end

function multi_nested_double()
    pbar = ProgressBar(; refresh_rate=60, expand=false, width=150)
    with(pbar) do
        outer = addjob!(pbar; N=3, description="outer")
        for i in 1:3
            inner = addjob!(pbar, N=100, description="inner $i")
            inner2 = addjob!(pbar, N=100, description="inner $i v2")
            for j in 1:100
                update!(inner)
                update!(inner2)
                sleep(0.005)
            end

            update!(outer)
            removejob!(pbar, inner)
        end
    end
end

function multi(; kwargs...)
    pbar = ProgressBar(; refresh_rate=60, expand=false, width=150, kwargs...)
    j1 = addjob!(pbar; N=50, description="First")
    j2 = addjob!(pbar; N=75, description="Second")
    j3 = addjob!(pbar; N=100, description="Third")

    text = [
        "   [italic white]Let",
        "   [green]the",
        "   [bright_blue]texts",
        "   [white]be",
        Panel("[bold red underline]shown!"; fit=true)
    ]
    idx = 1
    with(pbar) do
        for i in 1:100
            i % 20 == 0 && begin
                tprintln(text[idx])
                idx += 1
            end


            update!(j1)
            update!(j2)
            update!(j3)
            sleep(0.025)
        end
    end
end


function spinner()
    for spinner in keys(SPINNERS)
        columns_kwargs = Dict(
            :SpinnerColumn => Dict(:spinnertype => spinner, :style=>"bold green"),
            :CompletedColumn => Dict(:style => "dim")
        )

        pbar = ProgressBar(; columns=:spinner, columns_kwargs=columns_kwargs)
        with(pbar) do
            job = addjob!(pbar; description="[orange1]$spinner...")
            for i in 1:500
                update!(job)
                sleep(.0025)
            end
        end
    end
end


function stdouttest()
    pbar = ProgressBar(;)
    job = addjob!(pbar; N=500, description="[blue]$spinner...")
    
    with(pbar) do
        for i in 1:500
            update!(job)
            sleep(.001)
            if i % 100 == 0
                println("test")
            end
        end
    end
end




clear()
println("starting")
print("_"^150)
simple(; transient=true, columns=:detailed)
# println("test")
# multi_nested()
# multi_nested_double()
multi(; transient=true)
# spinner()
println("done")



# TODO look at integrating with loggr stuff


