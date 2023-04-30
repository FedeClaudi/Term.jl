module Tprint

import Term:
    unescape_brackets, escape_brackets, has_markup, reshape_text, NOCOLOR, cleantext
import Term: highlight as highlighter
import ..Measures: Measure
import ..Renderables: AbstractRenderable, trim_renderable, RenderableText
import ..Style: apply_style
import ..Layout: hstack
import ..Consoles: console_width

export tprint, tprintln

function sprint_no_color(x)
    o = sprint(print, x)
    NOCOLOR[] && (o = cleantext(o))
    return o
end

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

"""
---
    tprint(x::AbstractString)

Apply style to a string and print it
"""
function tprint(io::IO, x::AbstractString; highlight = true)
    x = (highlight ? apply_style ∘ highlighter : apply_style)(x)

    x =
        Measure(x).w <= console_width(io) ? x :
        string(RenderableText(string(x), width = console_width(io)))
    print(io, sprint_no_color(x))
end

"""
---
    tprint(x::AbstractRenderable)

Print an `AbstractRenderable`.

Equivalent to `print(x)`
"""
function tprint(io::IO, x::AbstractRenderable; highlight = true)
    w = console_width()
    x = x.measure.w > console_width() ? trim_renderable(x, w) : x
    print(io, sprint_no_color(x))
end

function tprint(io::IO, args...; highlight = true)
    for (n, arg) in enumerate(args)
        tprint(io, arg; highlight = highlight)

        (n < length(args) && args[n + 1] isa AbstractRenderable) || print(io, " ")
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
tprintln(io::IO, args...; highlight = true) =
    tprint(io, args..., "\n"; highlight = highlight)

end
