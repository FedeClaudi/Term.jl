import Term: Panel

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
        Segment("""
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
        Panel(
        Segment("""
        [green]This is a multiline text[/]
        [on_black]This line is [bold]different!"""),
        style="blue dim",
        title="From Segment",
        width=50,
        justify=:center,
        title_style="red bold"

    ),
    justify=:center, title="created with Term", title_style="gray62"
    )
)