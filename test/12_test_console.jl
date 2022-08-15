using Term.Consoles
import Term: tprint, tprintln

println("\nTesting tprint, stdout temporarily disabled")

@suppress_out begin
    @testset "\e[34mTPRINT" begin
        @test_nothrow tprint("string")
        @test_nothrow tprint("{red}adasd{/red}")
        @test_nothrow tprint("{blue on_green}adasda")
        @test_nothrow tprint("{red}dadas{green}insdai{/green}outssdrse{blue}fsfsf{/blue}")
        @test_nothrow tprint(Panel("test"))
        @test_nothrow tprint(TextBox("test"))
        @test_nothrow tprint(1)
        @test_nothrow tprint(:x)
        @test_nothrow tprint(1, Panel("test"), "test")
        @test_nothrow tprintln("test")
        @test_nothrow tprintln(Panel("test"))
        @test_nothrow tprintln(1, Panel("test"), "test")

        @test_nothrow tprint(stdout, "string")
        @test_nothrow tprint(stdout, "{red}adasd{/red}")
        @test_nothrow tprint(stdout, "{blue on_green}adasda")
        @test_nothrow tprint(
            stdout,
            "{red}dadas{green}insdai{/green}outssdrse{blue}fsfsf{/blue}",
        )
        @test_nothrow tprint(stdout, Panel("test"))
        @test_nothrow tprint(stdout, TextBox("test"))
        @test_nothrow tprint(stdout, 1)
        @test_nothrow tprint(stdout, :x)
        @test_nothrow tprint(stdout, 1, Panel("test"), "test")
        @test_nothrow tprintln(stdout, "test")
        @test_nothrow tprintln(stdout, Panel("test"))
        @test_nothrow tprintln(stdout, 1, Panel("test"), "test")
    end
end

@testset "\e[34mCONSOLE" begin
    @test console_height() == displaysize(stdout)[1]

    @test console_width() == TEST_CONSOLE_WIDTH

    @test sprint(cursor_position) == "\e[6n"
    @test sprint(up) == "\e[1A"
    @test sprint(beginning_previous_line) == "\e[F"
    @test sprint(down) == "\e[1B"
    @test sprint(clear) == "\e[2J"
    @test sprint(hide_cursor) == "\e[?25l"
    @test sprint(show_cursor) == "\e[?25h"
    @test sprint(line) == "\n"
    @test sprint(prev_line) == "\e[1F"
    @test sprint(next_line) == "\e[1E"
    @test sprint(erase_line) == "\e[2K"
    @test sprint(cleartoend) == "\e[0J"
    @test sprint(move_to_line) == "\e[1;1H"
    @test sprint(change_scroll_region) == "\e[1;1r\e[1B"
    @test sprint(savecursor) == "\e[s"
    @test sprint(restorecursor) == "\e[u"
end
