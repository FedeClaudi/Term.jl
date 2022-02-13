import Term

strings = [

    "[red]color[/red]",
    "[white bold]mode[/white bold]",
    "[black on_red]background[/black on_red]",
    "[red]nested [green]inside[/green] colors[/red]",
    """
        test
        multiple
        lines
    """,
    """
        [red]test[/red]
        multiple
        lines
    """,
]

"""
    Failing

        [red]test
            on
            multiple
            lines
        [/red]

        [red]
            test
            on
            multiple
            lines
        [/red]
"""

for string in strings
    print("\n\n")
    @info "Processing" string
    print("\n")
    tprint(string)

    text = MarkupText(string)
    println(text)
end