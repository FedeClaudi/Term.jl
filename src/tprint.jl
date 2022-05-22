module Tprint

import Term: theme, unescape_brackets, escape_brackets
import Term: highlight as highlighter
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

tprint(x; highlight=true) = tprint(stdout, x; highlight=highlight)

tprint(io::IO, x; highlight=true) = tprint(
    io, 
    escape_brackets(string(x));
    highlight=highlight
)

            
tprint(io::IO, x::AbstractVector; highlight=true) = highlight ?
    print(io, "[" * (apply_style ∘ highlighter)(x) * "]") :
    tprint(io, escape_brackets(string(x)); highlight=false)


tprint(io::IO, ::MIME"text/html", x; highlight=true) = tprint(io, x; highlight=highlight)


"""
tprint(x::AbstractString)

Apply style to a string and print it
"""
tprint(io::IO, x::AbstractString; highlight=true) = highlight ?
        print(io, (apply_style ∘ highlighter ∘ unescape_brackets)(x)) :
        # print(io, (apply_style ∘ highlighter ∘  unescape_brackets)(x)) :
        print(io, (unescape_brackets ∘  apply_style)(x))

"""
tprint(x::AbstractRenderable)

Print an `AbstractRenderable`.

Equivalent to `println(x)`
"""
tprint(io::IO, x::AbstractRenderable; highlight=true) =  print(io, x; highlight=highlight)


# tprint(x::Symbol)

# Print highlighted as a Symbol
# """
# tprint(io::IO, x::Symbol; highlight=true) = tprint(io, highlight(":" * string(x), :symbol))

# """
# tprint(x::Number)

# Print highlighted as a Number
# """
# tprint(io::IO, x::Number) = tprint(io, highlight(string(x), :number))

# """
# tprint(x::Function)

# Print highlighted as a Function
# """
# tprint(io::IO, x::Function) = tprint(io, highlight(string(x), :func))

# """
# tprint(x::DataType)

# Print highlighted as a DataType
# """
# tprint(io::IO, x::DataType) = tprint(io, highlight(string(x), :type))



function tprint(io::IO, args...)
    for (n, arg) in enumerate(args)
        tprint(io, arg)

        if n < length(args)
            args[n+1] isa AbstractRenderable || print(io, " ")
        end
    end
    return nothing
end

function tprint(args...; highlight=true)
    for (n, arg) in enumerate(args)
        tprint(arg; highlight=highlight)

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
tprintln(x; highlight=true) = tprint(x, "\n"; highlight=highlight)
tprintln(args...; highlight=true) = tprint(args..., "\n"; highlight=highlight)

tprintln(io::IO, x; highlight=true) = tprint(io, x, "\n"; highlight=highlight)
tprintln(io::IO, args...; highlight=true) = tprint(io, args..., "\n"; highlight=highlight)


end