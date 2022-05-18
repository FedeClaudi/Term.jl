

"""
Showing how to use Term.jl to create styled console representation for your types.
"""

using Term: Panel

struct myType
    name::String
    height::Int
    width::Int
    mass::Float64
end

""" get string representation """
Base.string(obj::myType) = """
[bold]height:[/bold] [bright_blue]$(obj.height)[/bright_blue]
[bold]width:[/bold]  [bright_blue]$(obj.width)[/bright_blue]
[bold]mass:[/bold]   [green]$(obj.mass)[/green]"""

""" Custom show method """
Base.show(io::IO, ::MIME"text/plain", obj::myType) =
    print(io, string(
        Panel(string(obj); 
        title=obj.name,
        style="red dim",
        title_style="default bright_red bold",
        fit=true, padding=(2, 2, 1, 1)
        )
    )
)



obj = myType("Rocket", 10, 10, 99.9)