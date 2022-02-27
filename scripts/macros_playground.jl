using Revise

Revise.revise()

using Term

println(@green "Metaprogramming is great!")
println(@underline "Made with [green]Term.jl[/green]")


println(@style "This is my text, effortlessly [black bold on_red]styled![/black bold on_red]" bold blue underline)