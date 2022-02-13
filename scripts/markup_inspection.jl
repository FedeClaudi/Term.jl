using Revise
Revise.revise()

using Term


"""
    Visual inspection of correctly markp up text parsing
"""

# @info "Color red"
# tprint("[red]Red[/red] [white bold]Bold[/white bold] [on_red]background[/on_red]")

# @info "Background color"
# tprint("[red on_black bold]combo[/red on_black bold]")

@info "nested"
tprint("[red]This is a [green]nested[/green] text![/red]")
tprint("[back on_red]This is a [bold]nested[/bold] text![/back on_red]")


@info "double nested"
# tprint("[red]This is a [green]nested text [blue] within another nested[/blue][/green] text![/red]")
# tprint("[red]This is a [green]nested text [blue] within another nested[/blue] text[/green] red![/red]")