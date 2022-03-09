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

@timeit_include("00_empty.jl")

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

print("\n\n")
@timeit_include("10_test_logging.jl")

print("\n\n")
@timeit_include("11_test_errors.jl")

print("\n\n")
@timeit_include("12_test_console.jl")

show(TIMEROUTPUT; compact = true, sortby = :firstexec)
println("\n")
