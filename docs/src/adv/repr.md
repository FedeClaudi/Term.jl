# Console type display

You can use `Term.jl` to create a styled type display in your console. 
The easiest way to explain it is by way of example.
Let's say you define a type, and create an instance of it:


```@example repr
using Term

struct myType
    name::String
    height::Int
    width::Int
    mass::Float64
end


obj = myType("Rocket", 10, 10, 99.9)
```

as you can see the default way to represent your object in the console is not very exciting. So what you can do is define a `Base.show` method for your type and use Term to make it fancy!

First, you'll probably want a way to create a string representation of your type (possibly with markdown styling, go crazy with it!)

```@example repr
""" get string representation """
Base.string(obj::myType) = """
[bold]height:[/bold] [bright_blue]$(obj.height)[/bright_blue]
[bold]width:[/bold]  [bright_blue]$(obj.width)[/bright_blue]
[bold]mass:[/bold]   [green]$(obj.mass)[/green]"""

tprint(string(obj))
```

and then, you can use this string and create other stuff around it!
```@example repr

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

obj
```


That's it! Enjoy