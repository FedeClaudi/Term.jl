using Term
using Test
using Suppressor

function testpanel(p, w, h)
    # check all lines have the same length
    _p = string(p)

    dw = displaysize(stdout)[2]
    if isnothing(w) || w > dw
        return
    else
        widths = textwidth.(cleantext.(split(_p, "\n")))
    end
    
    # println(p, p.measure, widths)
    @test length(unique(widths)) == 1

    # check it has the right measure
    if !isnothing(w)
        @test p.measure.w == w
        @test textlen(cleantext(p.segments[1].text)) == w
        @test length(chars(cleantext(p.segments[1].text))) == w
    end

    if !isnothing(h)
        @test p.measure.h == h
        @test length(p.segments) == h
    end
end


nlines(x) = length(split(x, "\n"))
lw(x) = max(length.(split(x, "\n"))...)

using TimerOutputs: TimerOutputs, @timeit
const TIMEROUTPUT = TimerOutputs.TimerOutput()

macro timeit_include(path::AbstractString)
    return :(@timeit TIMEROUTPUT $path include($path))
end


tprint("\n[bold blue]Runing all tests measuring timing and allocations\n")


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
tprint("\n\n[bold green]Running: '04_test_markup_and_style.jl' ")
@time @timeit_include("04_test_markup_and_style.jl")

 # ? 5 macros
tprint("\n\n[bold green]Running: '05_test_macros.jl' ")
@time @timeit_include("05_test_macros.jl")

 # ? 6 renderables
tprint("\n\n[bold green]Running: '06_test_renderables.jl' ")
@time @timeit_include("06_test_renderables.jl")

# ? 7 panel
tprint("\n\n[bold green]Running: '07_test_panel.jl' ")
@time @timeit_include("07_test_panel.jl")

# ? 8 layout
tprint("\n\n[bold green]Running: '08_test_layout.jl' ")
@time @timeit_include("08_test_layout.jl")

#  ? 9 inspect
tprint("\n\n[bold green]Running: '09_test_inspect.jl' ")
@time @timeit_include("09_test_inspect.jl")

# ? 11 console
tprint("\n\n[bold green]Running: '11_test_console.jl' ")
@time @timeit_include("11_test_console.jl")

# ? 12 logging
 tprint("\n\n[bold green]Running: '12_test_logging.jl' ")
 @time @timeit_include("12_test_logging.jl")

# ? 99 errors
 tprint("\n\n[bold green]Running: '99_test_errors.jl' ")
 @time @timeit_include("99_test_errors.jl")



show(TIMEROUTPUT; compact = true, sortby = :firstexec)
println("\n")
