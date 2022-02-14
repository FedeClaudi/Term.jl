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

    # nested
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

        # nested
        "[red] out [green]inside [blue] blue [/blue] now green [/green] test [/red]"

        "[red] out [green]inside [blue]more inside [/blue] now green [/green] test[blue] then some blue [/blue] and red [/red]"
"""

for string in strings
    # print("\n\n")
    # @info "Processing" string
    print("\n")
    tprint(string)

    # text = MarkupText(string)
    # println(text)
end