
"""
Showing how to use Term.jl to create styled console representation for your types.
"""

using Term: Panel, vLine, rvstack, lvstack, RenderableText, @with_repr, termshow

struct myType
    name::String
    height::Int
    width::Int
    mass::Float64
end

""" Custom show method """
function Base.show(io::IO, ::MIME"text/plain", obj::myType)
    fields = (:height, :width, :mass)

    info = map(f -> RenderableText(string(f); style = "bold"), fields)
    vals = map(
        f -> RenderableText(" " * string(getfield(obj, f)); style = "bright_blue"),
        fields,
    )
    obj_details = rvstack(info...) * vLine(3; style = "dim") * lvstack(vals...)

    return print(
        io,
        Panel(
            obj_details;
            title = obj.name,
            style = "red dim",
            title_style = "default bright_red bold",
            fit = true,
            padding = (2, 2, 1, 1),
        ),
    )
end

obj = myType("Rocket", 10, 10, 99.9)

# or just use our macro!

@with_repr mutable struct myRocket
    width::Int
    height::Int
    mass::Float64
    engines_activity::Vector

    manufacturer::String
end

obj = myRocket(10, 50, 5000, [1.1, 123123, 1], "NASA")
