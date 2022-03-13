import Term.consoles: console_height, console_width, console, err_console, Console
import Term: tprint, tprintln

println("\nTesting tprint, stdout temporarily disabled")

@suppress_out begin
    @testset "\e[34mTPRINT" begin
        @test_nowarn tprint("string")
        @test_nowarn tprint("[red]adasd[/red]")
        @test_nowarn tprint("[blue on_green]adasda")
        @test_nowarn tprint("[red]dadas[green]insdai[/green]outssdrse[blue]fsfsf[/blue]")

        @test_nowarn tprint(Panel("test"))
        @test_nowarn tprint(TextBox("test"))

        @test_nowarn tprint(1)
        @test_nowarn tprint(:x)

        @test_nowarn tprint(1, Panel("test"), "test")

        @test_nowarn tprintln("test")

        @test_nowarn tprintln(Panel("test"))

        @test_nowarn tprintln(1, Panel("test"), "test")
    end
end

@testset "\e[34mCONSOLE" begin
    @test console_height() == displaysize(stdout)[1]
    @test console_height(stdout) == displaysize(stdout)[1]

    @test console_width() == displaysize(stdout)[2]
    @test console_width(stdout) == displaysize(stdout)[2]

    @test Console(stdout) == Console()

end
