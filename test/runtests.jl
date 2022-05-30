using Term
using Test
using Suppressor
import Term: console_width

include("__test_utils.jl")

using TimerOutputs: TimerOutputs, @timeit
const TIMEROUTPUT = TimerOutputs.TimerOutput()

dotest = console_width() >= 88

# ? 0  - misc
tprint("{bold green}Running: '00_misc.jl' {/bold green}")
@time @timeit_include("00_misc.jl")

# ? 1  - text utils
tprint("{bold green}Running: '01_test_text_utils.jl' {/bold green}")
@time @timeit_include("01_test_text_utils.jl")

# ? 2 ansi
tprint("\n\n{bold green}Running: '02_test_ansi.jl' {/bold green}")  # ansi & col' {/bold green}")
@time @timeit_include("02_test_ansi.jl")

# ? 3 measure
tprint("\n\n{bold green}Running: '03_test_measure.jl' {/bold green}")
@time @timeit_include("03_test_measure.jl")

# ? 4 style
tprint("\n\n{bold green}Running: '04_test_style.jl' {/bold green}")
@time @timeit_include("04_test_style.jl")

# ? 5 macros
tprint("\n\n{bold green}Running: '05_test_macros.jl' {/bold green}")
@time @timeit_include("05_test_macros.jl")

# ? 6a box
tprint("\n\n{bold green}Running: '6a_test_box.jl' {/bold green}")
@time @timeit_include("6a_test_box.jl")

# ? 6 renderables
tprint("\n\n{bold green}Running: '06_test_renderables.jl' {/bold green}")
@time @timeit_include("06_test_renderables.jl")

# ? 7 panel
tprint("\n\n{bold green}Running: '07_test_panel.jl' {/bold green}")
@time @timeit_include("07_test_panel.jl")

# ? 8 layout
tprint("\n\n{bold green}Running: '08_test_layout.jl' {/bold green}")
@time @timeit_include("08_test_layout.jl")

#  ? 9 inspect
tprint("\n\n{bold green}Running: '09_test_inspect.jl' {/bold green}")
@time @timeit_include("09_test_inspect.jl")

# ? 11 console
tprint("\n\n{bold green}Running: '11_test_console.jl' {/bold green}")
@time @timeit_include("11_test_console.jl")

# ? 12 logging
tprint("\n\n{bold green}Running: '12_test_logging.jl' {/bold green}")
@time @timeit_include("12_test_logging.jl")

# ? 14 highlight
tprint("\n\n{bold green}Running: '14_test_highlight.jl' {/bold green}")
@time @timeit_include("14_test_highlight.jl")

# ? 15 progress
tprint("\n\n{bold green}Running: '15_test_progress.jl' {/bold green}")
@time @timeit_include("15_test_progress.jl")

# ? 16 Tree
tprint("\n\n{bold green}Running: '16_test_tree.jl' {/bold green}")
@time @timeit_include("16_test_tree.jl")

# ? 17 Dendogram
tprint("\n\n{bold green}Running: '17_test_dendogram.jl' {/bold green}")
@time @timeit_include("17_test_dendogram.jl")

# ? 18 Dendogram
tprint("\n\n{bold green}Running: '18_test_table.jl' {/bold green}")
@time @timeit_include("18_test_table.jl")

# ? 999 EXAMPLES
tprint("\n\n{bold green}Running: '999_test_examples.jl' {/bold green}")
@time @timeit_include("999_test_examples.jl")

# ? 99 ERRORS
tprint("\n\n{bold green}Running: '99_test_errors.jl' {/bold green}")
@time @timeit_include("99_test_errors.jl")

show(TIMEROUTPUT; compact = true, sortby = :firstexec)
println("\n")
