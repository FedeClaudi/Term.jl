import Term.consoles: console_height, console_width, console, err_console, Console
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
    end
end

@testset "\e[34mCONSOLE" begin
    @test console_height() == displaysize(stdout)[1]
    @test console_height(stdout) == displaysize(stdout)[1]

    @test console_width() == displaysize(stdout)[2]
    @test console_width(stdout) == displaysize(stdout)[2]

    @test Console(stdout) == Console()

end
