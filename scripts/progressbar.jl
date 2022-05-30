using ProgressLogging

using Term.progress
import Term.Console: clear, cursor_position
import Term.Progress: SPINNERS
import Term: tprintln, Panel, install_term_logger

install_term_logger()

function simple(; kwargs...)
    pbar = ProgressBar(; refresh_rate = 60, expand = false, width = 150, kwargs...)
    j1 = addjob!(pbar; N = 100, description = "First")

    with(pbar) do
        for i in 1:100
            update!(j1)
            sleep(0.01)
        end
    end
end

function simple_slow(; kwargs...)
    pbar = ProgressBar(;
        refresh_rate = 60,
        expand = false,
        columns = :detailed,
        width = 150,
        kwargs...,
    )
    j1 = addjob!(pbar; N = 5, description = "First")

    with(pbar) do
        for i in 1:5
            for k in 1:10000
                x = rand(100, 100)
                y = x .^ 2 .- rand(100, 100)
                # yield()
            end

            update!(j1)
            # println(i)
            # sleep(.001)
        end
    end
end

function multi_nested()
    pbar = ProgressBar(; refresh_rate = 60, expand = false, width = 150)
    with(pbar) do
        outer = addjob!(pbar; N = 3, description = "outer")
        for i in 1:3
            println("iii", i)
            inner = addjob!(pbar; N = 100, description = "inner $i")
            for j in 1:100
                update!(inner)
                sleep(0.005)
            end

            update!(outer)
            removejob!(pbar, inner)
            sleep(1)
        end
    end
end

function multi_nested_double()
    pbar = ProgressBar(; refresh_rate = 60, expand = false, width = 150)
    with(pbar) do
        outer = addjob!(pbar; N = 3, description = "outer")
        for i in 1:3
            println(i)
            inner = addjob!(pbar; N = 100, description = "inner $i")
            inner2 = addjob!(pbar; N = 100, description = "inner $i v2")
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
    pbar = ProgressBar(; refresh_rate = 60, expand = false, width = 150, kwargs...)
    j1 = addjob!(pbar; N = 50, description = "First")
    j2 = addjob!(pbar; N = 75, description = "Second")
    j3 = addjob!(pbar; N = 100, description = "Third")

    text = [
        "   [italic white]Let",
        "   [green]the",
        "   [bright_blue]texts",
        "   [white]be",
        Panel("[bold red underline]shown!"; fit = true),
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
            :SpinnerColumn => Dict(:spinnertype => spinner, :style => "bold green"),
            :CompletedColumn => Dict(:style => "dim"),
        )

        pbar = ProgressBar(; columns = :spinner, columns_kwargs = columns_kwargs)
        with(pbar) do
            job = addjob!(pbar; description = "[orange1]$spinner...")
            for i in 1:500
                update!(job)
                sleep(0.0025)
            end
        end
    end
end

function mixed()
    columns_kwargs = Dict(
        :SpinnerColumn => Dict(:style => "bold green"),
        :CompletedColumn => Dict(:style => "dim"),
    )

    pbar = ProgressBar(; columns_kwargs = columns_kwargs)
    with(pbar) do
        j1 = addjob!(pbar; N = length(keys(SPINNERS)))

        for spinner in keys(SPINNERS)
            update!(j1)
            job = addjob!(pbar; description = "...")
            for i in 1:500
                update!(job)
                sleep(0.001)
            end
        end
    end
end

function transientjobs()
    columns_kwargs = Dict(
        :SpinnerColumn => Dict(:style => "bold green"),
        :CompletedColumn => Dict(:style => "dim"),
    )

    pbar = ProgressBar(; columns_kwargs = columns_kwargs)
    with(pbar) do
        j1 = addjob!(pbar; N = length(keys(SPINNERS)))

        for spinner in keys(SPINNERS)
            println(spinner)
            update!(j1)
            job = addjob!(pbar; N = 500, description = "...", transient = true)
            for i in 1:500
                update!(job)
                sleep(0.001)
            end
        end
    end
end

function progresslogging()
    @progress "outer...." for i in 1:6
        @progress "inner... $i" for j in 1:100
            sleep(0.01)
        end
    end
end

function _track()
    @track for i in 1:10
        sleep(0.1)
    end
end

function _track_slow()
    @track for i in 1:10
        for k in 1:10000
            x = rand(100, 100)
            y = x .^ 2 .- rand(100, 100)
        end
    end
end

clear()
println("starting")
print("_"^150)

# simple(; transient=false, columns=:detailed)
# multi(; transient=false)
# multi_nested()
# multi_nested_double()
# spinner()
# mixed()
# transientjobs()
# progresslogging()
# _track()

simple_slow()
# _track_slow()

println("done")
