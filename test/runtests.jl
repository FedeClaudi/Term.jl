using Suppressor
import Suppressor: @capture_out
using StableRNGs
using Term
using Test
import Term: console_width
import Term: Tree, Dendogram, Table, Compositor

const RNG = StableRNG(1337)

include("__test_utils.jl")

using TimerOutputs: TimerOutputs, @timeit
const TIMEROUTPUT = TimerOutputs.TimerOutput()

import Term.Consoles: Console, enable, disable

Term.DEBUG_ON[] = false
const TEST_DEBUG_MODE = false  # renderables are saved as strings
const TEST_CONSOLE_WIDTH = 80
const IS_WIN = Sys.iswindows()
con = Console(TEST_CONSOLE_WIDTH)
enable(con)

macro runner(fn)
    quote
        tprintln(
            $(
                "\n{bold green}Running:{/bold green} {underline bold white}'$fn'{/underline bold white}"
            ),
        )
        @time @timeit_include($fn)
    end |> esc
end

# @testset "Ambiguous methods" begin
#     @test Test.detect_ambiguities(Term; recursive=true)
# end

@runner "01_test_text_utils.jl"
@runner "02_test_ansi.jl"
@runner "03_test_measure.jl"
@runner "04_test_style.jl"
@runner "05_test_macros.jl"
@runner "06_test_box.jl"
@runner "07_test_renderables.jl"
@runner "08_test_panel.jl"
@runner "09_test_layout.jl"
@runner "10_test_inspect.jl"
@runner "11_test_theme.jl"
@runner "12_test_console.jl"
@runner "13_test_logs.jl"
@runner "14_test_highlight.jl"
@runner "15_test_progress.jl"
@runner "16_test_tree.jl"
@runner "17_test_dendogram.jl"
@runner "18_test_table.jl"
@runner "19_test_repr.jl"
@runner "20_test_compositor.jl"
@runner "21_test_markdown.jl"
@runner "22_test_grid.jl"
@runner "23_test_link.jl"
@runner "24_prompts.jl"
@runner "25_annotations.jl"
@runner "26_test_live.jl"
@runner "98_test_examples.jl"
@runner "99_test_errors.jl"

show(TIMEROUTPUT; compact = true, sortby = :firstexec)
println('\n')
disable(con)
