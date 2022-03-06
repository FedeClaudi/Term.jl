using Term
using Test



nlines(x) = length(split(x, "\n"))
lw(x) = max(length.(split(x, "\n"))...)

using TimerOutputs: TimerOutputs, @timeit
const TIMEROUTPUT = TimerOutputs.TimerOutput()

macro timeit_include(path::AbstractString)
    :(@timeit TIMEROUTPUT $path include($path))
end


print("\n\n")
@timeit_include("01_test_text_utils.jl")

print("\n\n")
@timeit_include("02_test_ansi.jl")  # ansi & color

print("\n\n")
@timeit_include("03_test_measure.jl")

print("\n\n")
@timeit_include("04_test_markup.jl")

print("\n\n")
@timeit_include("05_test_macros.jl")

print("\n\n")
@timeit_include("06_test_renderables.jl")

print("\n\n")
@timeit_include("07_test_layout.jl")

print("\n\n")
@timeit_include("08_test_panel.jl")

print("\n\n")
@timeit_include("09_test_inspect.jl")


show(TIMEROUTPUT; compact = true, sortby = :firstexec)
println("\n")
