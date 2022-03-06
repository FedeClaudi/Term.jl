# using Pkg
# Pkg.test("Term",coverage=true)

using Coverage
coverage = process_folder() # defaults to src/; alternatively, supply the folder name as argument
covered_lines, total_lines = get_summary(coverage)

import Term: Panel

res = "[blue][green]Covered[/green][white bold]/[/white bold][white]total[/white]: [green bold]$covered_lines[/green bold][white bold]/[/white bold][white bold]$total_lines[/red bold] ([yellow underline]$(round(covered_lines/total_lines, digits=3)* 100)%[/yellow underline])"

print("\n\n")
print(
    Panel(
        res,
        width=44,
        title="Term.jl",
        style="bold",
        justify=:center,
    )
)