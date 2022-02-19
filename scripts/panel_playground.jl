import Term: Panel, RenderableText, TextBox

println(
    Panel(
        """
        [green]This is a multiline text[/]
        [on_black]This line is [bold] different!""",
        style="red",
        title="From text"
    )
)


println(
    Panel(
        RenderableText("""
        [green]This is a multiline text[/]
        [on_black]This line is [bold]different!"""),
        style="blue dim",
        title="From Segment",
        width=50,
        justify=:center,
        title_style="red bold"

    )
)


println(
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
)



print(TextBox(
    join("TEST"^4, "sdfs"^8, "\n"), title="test box!"
))


print(TextBox(
    join("X"^26, "y"^8), title="test box!", title_style="bold red", width=44
))

print(TextBox(
    "[bold]test [/]"^25
))