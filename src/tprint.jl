module Tprint

import Term: unescape_brackets, escape_brackets, has_markup
import Term: highlight as highlighter

import ..Renderables: AbstractRenderable
import ..Style: apply_style
import ..Layout: hstack

export tprint, tprintln

"""
    tprint

Similar to standard lib's `print` function but with added
**styling functionality**

!!! tip "highlighting"
    Set `highlight=true` to automatically highlight the output.
"""
function tprint end

tprint(x; highlight = true) = tprint(stdout, x; highlight = highlight)

tprint(io::IO, x; highlight = true) = tprint(io, string(x); highlight = highlight)

tprint(io::IO, ::MIME"text/html", x; highlight = true) =
    tprint(io, x; highlight = highlight)

"""
---
    tprint(x::AbstractString)

Apply style to a string and print it
"""
tprint(io::IO, x::AbstractString; highlight = true) =
    print(io, (highlight ? apply_style ∘ highlighter : apply_style)(x))

"""
---
    tprint(x::AbstractRenderable)

Print an `AbstractRenderable`.

Equivalent to `println(x)`
"""
tprint(io::IO, x::AbstractRenderable; highlight = true) =
    print(io, x; highlight = highlight)

function tprint(io::IO, args...)
    for (n, arg) in enumerate(args)
        tprint(io, arg)

        if n < length(args)
            args[n + 1] isa AbstractRenderable || print(io, " ")
        end
    end
    return nothing
end

function tprint(args...; highlight = true)
    for (n, arg) in enumerate(args)
        tprint(arg; highlight = highlight)

        if n < length(args)
            args[n + 1] isa AbstractRenderable || print(" ")
        end
    end
    return nothing
end

"""
---
    tprintln

Similar to standard lib's `println` function but with added
styling functionality.
"""

tprintln(args...; highlight = true) = tprint(args..., "\n"; highlight = highlight)

end
