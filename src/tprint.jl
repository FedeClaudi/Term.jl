module Tprint

import ..renderables: AbstractRenderable
import Term: highlight, theme

import ..style: apply_style

export tprint
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
tprint(io::IO, x::AbstractString) = println(io, apply_style(x))
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
    map((x)->tprint(stdout, x), args)
    return nothing
end

end