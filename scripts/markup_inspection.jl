using Revise
Revise.revise()

using Term


"""
    Visual inspection of correctly markp up text parsing
"""

@info "Color red"
tprint("[red]Red[/red] [white bold]Bold[/white bold] [on_red]background[/on_red]")

@info "Background color"
tprint("[red on_black bold]combo[/red on_black bold]")

@info "nested"
tprint("[red]This is a [green]nested[/green] text![/red]")