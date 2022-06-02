# Consoles type display

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


For this example, we will have it so that showing `obj` in the REPR will create a  [`PanelDocs`](@ref PanelDocs) using `name` as the title and showing the other fields and values inside. 
```@example repr

""" Custom show method """
function Base.show(io::IO, ::MIME"text/plain", obj::myType)
    # fields to be shown inside the panel
    fields = (:height, :width, :mass)

    # get fields and values as `RenderableText` objects
    info = map(
        f -> RenderableText(string(f); style="bold"), fields
    )
    vals = map(
        f -> RenderableText(" "*string(getfield(obj, f)); style="bright_blue"), fields
    )

    # right justify and vertical stack info, left justify and stack values
    obj_details = rvstack(info...) * vLine(3; style="dim") * lvstack(vals...)

    # print the panel!
    print(io, 
        Panel(obj_details; 
        title=obj.name,
        style="red dim",
        title_style="default bright_red bold",
        fit=true, padding=(2, 2, 1, 1)
        )
    )
end

obj
```


## @with_repr

Maybe you don't want to go through all that for each type you define...
Fear not! Term has a macro for you:

```@example
using Term

@with_repr struct Rocket
    width::Int
    height::Int
    mass::Float64
    
    manufacturer::String
end

obj = Rocket(10, 50, 5000, "NASA")
```


## `termshow`
The examples above work when you're the one creating a new type, but how about when you're dealing with types defined in someone else's code?

For that you can use `termshow`: `termshow(x)` prints a `string` or `Panel` with the same kind of visualization you'd get from `@with_repr` - but for any type!
```@example
using Term
termshow(:(x+y))
```

In fact, you can do more, overwrite the default `show` method (at your own risk!) like so:
```@example repr
using Term
Base.show(io::IO, ::MIME"text/plain", obj) = print(io, termshow(obj))
```

And now the REPL will print fancy info for any object!
```@example repr
:(x + y)
```

```@example repr
struct Throttle end

struct Engine
    id::Int
    throttle::Throttle
end

e = Engine(1, Throttle())
```

And so on.... enjoy!