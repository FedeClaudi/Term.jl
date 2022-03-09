module consoles

import Term: highlight, theme

import ..renderables: AbstractRenderable
import ..style: apply_style

export Console, console, err_console, console_height, console_width, tprint

# ---------------------------------------------------------------------------- #
#                                    TPRINT                                    #
# ---------------------------------------------------------------------------- #

"""
    tprint

Similar to standard lib's `print` function but with added
styling functionality
"""
function tprint end

"""
    tprint(x::AbstractString)

Apply style to a string and print it to a new line
"""
tprint(x::AbstractString) = (println ∘ apply_style)(x)

"""
    tprint(x::AbstractRenderable)

Print an `AbstractRenderable`.

Equivalent to `println(x)`
"""
tprint(x::AbstractRenderable) = println(x)

"""
    tprint(x::Symbol)

Print highlighted as a Symbol
"""
tprint(x::Symbol) = tprint(highlight(":" * string(x), theme, :symbol))

"""
    tprint(x::Number)

Print highlighted as a Number
"""
tprint(x::Number) = tprint(highlight(string(x), theme, :number))

"""
    tprint(x::Function)

Print highlighted as a Function
"""
tprint(x::Function) = tprint(highlight(string(x), theme, :func))

"""
    tprint(x)

When no dedicated method is present, print the string representation
"""
tprint(x) = tprint(string(x))

function tprint(args...)
    map(tprint, args)
    return nothing
end

# ---------------------------------------------------------------------------- #
#                                    CONSOLE                                   #
# ---------------------------------------------------------------------------- #
"""
    Console

The `Console` object stores information about the dimensions of the output(::IO)
where objects will be printed
"""
struct Console
    io::IO
    width::Int
    height::Int
end

Console(io::IO) = Console(io, displaysize(io)[2], displaysize(io)[1])
Console() = Console(stdout)

console = Console(stdout)
err_console = Console(stderr)

"""
    console_height()

Get the current console height.
"""
console_height() = displaysize(stdout)[1]
console_height(io::IO) = displaysize(io)[1]

"""
    console_width()

Get the current console width.
"""
console_width() = displaysize(stdout)[2]
console_width(io::IO) = displaysize(io)[2]

end
