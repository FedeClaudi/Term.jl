module Tprint

import Term: highlight, theme
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

"""
tprint(x::AbstractString)

Apply style to a string and print it to a new line
"""
tprint(io::IO, x::AbstractString) = print(io, apply_style(x))
tprint(x::AbstractString) = tprint(stdout, x)

"""
tprint(x::AbstractRenderable)

Print an `AbstractRenderable`.

Equivalent to `println(x)`
"""
tprint(x::AbstractRenderable) =  print(x)

"""
tprint(x::Symbol)

Print highlighted as a Symbol
"""
tprint(x::Symbol) = tprint(stdout, highlight(":" * string(x), theme, :symbol))

"""
tprint(x::Number)

Print highlighted as a Number
"""
tprint(x::Number) = tprint(stdout, highlight(string(x), theme, :number))

"""
tprint(x::Function)

Print highlighted as a Function
"""
tprint(x::Function) = tprint(stdout, highlight(string(x), theme, :func))

"""
tprint(x)

When no dedicated method is present, print the string representation
"""
tprint(x) = tprint(stdout, string(x))

function tprint(args...)
    for (n, arg) in enumerate(args)
        tprint(arg)

        if n < length(args)
            args[n+1] isa AbstractRenderable || print(" ")
        end
    end
    return nothing
end

tprintln(x) = tprint(x, "\n")
tprintln(args...) = tprint(args, "\n")

end