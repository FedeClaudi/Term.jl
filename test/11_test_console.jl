import Term.console: console_height,
        console_width,
        console,
        err_console,
        Console,
        cursor_position,
        up,
        beginning_previous_line,
        down, 
        clear,
        hide_cursor,
        show_cursor,
        line,
        erase_line
import Term: tprint, tprintln

println("\nTesting tprint, stdout temporarily disabled")

@suppress_out begin
    @testset "\e[34mTPRINT" begin
        @test_nothrow tprint("string")
        @test_nothrow tprint("[red]adasd[/red]")
        @test_nothrow tprint("[blue on_green]adasda")
        @test_nothrow tprint("[red]dadas[green]insdai[/green]outssdrse[blue]fsfsf[/blue]")
        @test_nothrow tprint(Panel("test"))
        @test_nothrow tprint(TextBox("test"))
        @test_nothrow tprint(1)
        @test_nothrow tprint(:x)
        @test_nothrow tprint(1, Panel("test"), "test")
        @test_nothrow tprintln("test")
        @test_nothrow tprintln(Panel("test"))
        @test_nothrow tprintln(1, Panel("test"), "test")


        @test_nothrow tprint(stdout, "string")
        @test_nothrow tprint(stdout, "[red]adasd[/red]")
        @test_nothrow tprint(stdout, "[blue on_green]adasda")
        @test_nothrow tprint(stdout, "[red]dadas[green]insdai[/green]outssdrse[blue]fsfsf[/blue]")
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
    @test console_height(stdout) == displaysize(stdout)[1]

    @test console_width() == displaysize(stdout)[2]
    @test console_width(stdout) == displaysize(stdout)[2]

    @test Console(stdout) == Console()


    @test_nothrow cursor_position()
    @test_nothrow up()
    @test_nothrow beginning_previous_line()
    @test_nothrow down()
    @test_nothrow clear()
    @test_nothrow hide_cursor()
    @test_nothrow show_cursor()
    @test_nothrow line()


    @test_nothrow cursor_position(stdout)
    @test_nothrow up(stdout)
    @test_nothrow beginning_previous_line(stdout)
    @test_nothrow down(stdout)
    @test_nothrow clear(stdout)
    @test_nothrow hide_cursor(stdout)
    @test_nothrow show_cursor(stdout)
    @test_nothrow line(stdout)

end
