using Term
using Test
using Suppressor

include("__test_utils.jl")

using TimerOutputs: TimerOutputs, @timeit
const TIMEROUTPUT = TimerOutputs.TimerOutput()

tprint("\n[bold blue]Runing all tests measuring timing and allocations\n")


# ? 0  - misc
tprint("[bold green]Running: '00_misc.jl' ")
@time @timeit_include("00_misc.jl")

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

# # ? 12 logging
tprint("\n\n[bold green]Running: '12_test_logging.jl' ")
@time @timeit_include("12_test_logging.jl")

# ? 13 box
tprint("\n\n[bold green]Running: '13_test_box.jl' ")
@time @timeit_include("13_test_box.jl")

# ? 14 highlight
tprint("\n\n[bold green]Running: '14_test_highlight.jl' ")
@time @timeit_include("14_test_highlight.jl")

# ? 15 progress
tprint("\n\n[bold green]Running: '15_test_progress.jl' ")
@time @timeit_include("15_test_progress.jl")

# ? 16 5433
tprint("\n\n[bold green]Running: '16_test_tree.jl' ")
@time @timeit_include("16_test_tree.jl")

# ? ERRORS
tprint("\n\n[bold green]Running: '99_test_errors.jl' ")
@time @timeit_include("99_test_errors.jl")

# ? EXAMPLES
tprint("\n\n[bold green]Running: '999_test_examples.jl' ")
@time @timeit_include("999_test_examples.jl")

show(TIMEROUTPUT; compact = true, sortby = :firstexec)
println("\n")
