module Tprint

import Term: highlight, theme, unescape_brackets
import ..renderables: AbstractRenderable
import ..style: apply_style
import ..layout: hstack

export tprint, tprintln
"""
tprint

Similar to standard lib's `print` function but with added
styling functionality
"""
function tprint end
tprint(x) = tprint(stdout, x)
tprint(io::IO, x) = tprint(io, x)
tprint(io::IO, ::MIME"text/html", x) = tprint(io, x)

"""
tprint(x::AbstractString)

Apply style to a string and print it to a new line
"""
tprint(io::IO, x::AbstractString) = print(io, (unescape_brackets ∘  apply_style)(x))

"""
tprint(x::AbstractRenderable)

Print an `AbstractRenderable`.

Equivalent to `println(x)`
"""
tprint(io::IO, x::AbstractRenderable) =  print(io, x)

"""
tprint(x::Symbol)

Print highlighted as a Symbol
"""
tprint(io::IO, x::Symbol) = tprint(io, highlight(":" * string(x), :symbol))

"""
tprint(x::Number)

Print highlighted as a Number
"""
tprint(io::IO, x::Number) = tprint(io, highlight(string(x), :number))

"""
tprint(x::Function)

Print highlighted as a Function
"""
tprint(io::IO, x::Function) = tprint(io, highlight(string(x), :func))

"""
tprint(x::DataType)

Print highlighted as a DataType
"""
tprint(io::IO, x::DataType) = tprint(io, highlight(string(x), :type))

"""
tprint(x)

When no dedicated method is present, print the string representation
"""
tprint(io::IO, x) = tprint(io, string(x))

function tprint(io::IO, args...)
    for (n, arg) in enumerate(args)
        tprint(io, arg)

        if n < length(args)
            args[n+1] isa AbstractRenderable || print(io, " ")
        end
    end
    return nothing
end

function tprint(args...)
    for (n, arg) in enumerate(args)
        tprint(arg)

        if n < length(args)
            args[n+1] isa AbstractRenderable || print(" ")
        end
    end
    return nothing
end

"""
    tprintln

Similar to standard lib's `println` function but with added
styling functionality.
"""
tprintln(x) = tprint(x, "\n")
tprintln(args...) = tprint(args..., "\n")

tprintln(io::IO, x) = tprint(io, x, "\n")
tprintln(io::IO, args...) = tprint(io, args..., "\n")

end