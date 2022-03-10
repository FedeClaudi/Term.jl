using Term
using Test
using Suppressor

# using Pkg
# Pkg.test("Term",coverage=true)

nlines(x) = length(split(x, "\n"))
lw(x) = max(length.(split(x, "\n"))...)

using TimerOutputs: TimerOutputs, @timeit
const TIMEROUTPUT = TimerOutputs.TimerOutput()

macro timeit_include(path::AbstractString)
    return :(@timeit TIMEROUTPUT $path include($path))
end


tprint("\n[bold blue]Runing all tests measuring timing and allocations")


# ? 1  - text utils
tprint("[bold green]Running: '01_test_text_utils.jl' ")
@time @timeit_include("01_test_text_utils.jl")

 # ? 2 ansi
tprint("\n\n[bold green]Running: '02_test_ansi.jl")  # ansi & col' ")
@time @timeit_include("02_test_ansi.jl")  

 # ? 3 measure
tprint("\n\n[bold green]Running: '03_test_measure.jl' ")
@time @timeit_include("03_test_measure.jl")

 # ? 4 markup
tprint("\n\n[bold green]Running: '04_test_markup.jl' ")
@time @timeit_include("04_test_markup.jl")

 # ? 5 macros
tprint("\n\n[bold green]Running: '05_test_macros.jl' ")
@time @timeit_include("05_test_macros.jl")

 # ? 6 renderables
tprint("\n\n[bold green]Running: '06_test_renderables.jl' ")
@time @timeit_include("06_test_renderables.jl")

 # ? 7 layout
tprint("\n\n[bold green]Running: '07_test_layout.jl' ")
@time @timeit_include("07_test_layout.jl")

 # ? 8 panel
tprint("\n\n[bold green]Running: '08_test_panel.jl' ")
@time @timeit_include("08_test_panel.jl")

 # ? 9 inspect
# tprint("\n\n[bold green]Running: '09_test_inspect.jl' ")
# @time @timeit_include("09_test_inspect.jl")

 # ? 10 errors
 tprint("\n\n[bold green]Running: '10_test_errors.jl' ")
 @time @timeit_include("10_test_errors.jl")


 # ? 11 console
tprint("\n\n[bold green]Running: '11_test_console.jl' ")
@time @timeit_include("11_test_console.jl")

 # ? 12 logging
 tprint("\n\n[bold green]Running: '12_test_logging.jl' ")
 @time @timeit_include("12_test_logging.jl")

show(TIMEROUTPUT; compact = true, sortby = :firstexec)
println("\n")
