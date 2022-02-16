import Term: Panel, Segment



@testset "PANEL base" begin
    Panel("[#ffffff]Start", title="OK", title_style="red")
    Panel("[(12, 55, 12)]Start", title="sfsd", title_style="#ffdd00")
    Panel("[bold on_red]Start", title="_)++")
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