import Term: Panel, Segment



@testset "PANEL base" begin
    Panel("[#ffffff]Start", title="OK", title_style="red")
    Panel("[(12, 55, 12)]Ssdfsdftart", title="s", title_style="#ffdd00")
    Panel("[bold on_red]Stasdfsdfrt", title="+")
    Panel("[bold]Start[/]sdfs\ndfsfsd\nfasdasdawdwdadaw\n", title="OK", title_style="red")
end



@testset "PANEL justify" begin
    Panel("[#ffffff]Start", title="OK", title_style="red", justify=:left)
    Panel("[#ffffff]Start", title="OK", title_style="red", justify=:center)
    Panel("[#ffffff]Start", title="OK", title_style="red", justify=:right)

    Panel("[#ffffff]Start", width=100, title="OK", title_style="red", justify=:left)
    Panel("[#ffffff]Start", width=100, title="OK", title_style="red", justify=:center)
    Panel("[#ffffff]Start", width=100, title="OK", title_style="red", justify=:right)
end


@testset "PANEL nested" begin
    t = Segment("[red]test")
    p1 = Panel(t, style="(.1, .3, .5)")
    p2 = Panel("test string", title="ok")
    p3 = Panel(p1, p2)


end