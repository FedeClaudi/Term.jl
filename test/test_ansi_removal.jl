import Term: remove_ansi
import Term: Segment


@testset "ANSI removal" begin
    t1 = Segment("[red bold]test").text
    @test length(remove_ansi(t1)) == 4


    t1 = Segment("[(255,255,255) on_black]test[/][bold dim]test").text
    @test length(remove_ansi(t1)) == 8


    t1 = Segment("[black underline]te[red on_blue]st[/][/]").text
    @test length(remove_ansi(t1)) == 4
end