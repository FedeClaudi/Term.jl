import Term.Style: apply_style
import Term: Panel

pts = """Lorem[red] ipsum dolor s[/red]it amet, consectetur adipiscing elit,
ed do eiusmod tempor [bold blue]incididu[underline]nt ut labore et dolore magna aliqua. Ut enim ad minim
 veniam, quis nos[/underline]trud exercitation ullamco laboris nisi ut aliquip ex 
 ea commodo consequat. Duis aute [/bold blue][red on_black]irure dolor in reprehenderit 
 in voluptate velit esse cillum dolore eu fugiat nulla 
 pariatur. Excepteur sint occaecat[/red on_black] cupidatat non proident, 
 sunt in [green]culpa qui officia[/green] deserunt mollit anim 
 id est laborum."""

print(apply_style(pts))
@time apply_style(pts);

p2 = apply_style(pts)
@time print(Panel(pts; style = "red"))
