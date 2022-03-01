using Revise

Revise.revise()

using Term
import Term: install_stacktrace

install_stacktrace()

println(@green "Metaprogramming is great!")
println(@underline "Made with [green]Term.jl[/green]")


println(@style "This is my text, effortlessly [black bold on_red]styled![/black bold on_red]" bold blue underline)