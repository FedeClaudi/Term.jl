import Term: Panel, Segment, RenderableText, TextBox



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


    Panel(
        Panel("[bold white]Title panel!!", style="dim"),
        Panel(RenderableText("""
        [green]This is a multiline text[/]
        [on_black]This line is [bold]different!
        """),
        style="blue dim",
        title="From Segment",
        width=50,
        justify=:center,
        title_style="red bold",
        subtitle="test",
        subtitle_justify=:right,
    ),
    justify=:center, title="created with Term", title_style="gray62"
    )
end


@testset "TextBox" begin
    print(TextBox(
        join("TEST"^4, "sdfs"^8, "\n"), title="test box!"
    ))


    print(TextBox(
        join("TE|∫√T"^4, "sdfs"^8, "\n"), title="test box!"
    ))
end