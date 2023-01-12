module Measures

import Term: rint, remove_ansi, remove_markup, default_width, DEFAULT_ASPECT_RATIO, textlen
import Base: ==
export Measure

"""
    Measure

Stores the size of a piece of renderable material.
"""
mutable struct Measure
    h::Int
    w::Int
end

Base.string(M::Measure) = "(h: $(M.h), w: $(M.w))"
Base.show(io::IO, M::Measure) = print(io, "Measure (h: $(M.h), w: $(M.w))")

"""
    default_size()

Returns default size (h, w).
"""
default_size() = (rint(default_width() / 2DEFAULT_ASPECT_RATIO[]), default_width())

"""
    Measure(str::String)

Constructs a measure object from a string
"""
function Measure(str::AbstractString)
    str = remove_markup(remove_ansi(str); remove_orphan_tags = false)
    lines = split(str, '\n')
    return Measure(length(lines), maximum(textlen.(lines; remove_orphan_tags = false)))
end

Measure(::Nothing) = Measure(0, 0)
Measure() = Measure(0, 0)

"""
The sum of measures returns a measure with the highest value along each dimension.
"""
Base.:+(m1::Measure, m2::Measure)::Measure = Measure(m1.h + m2.h, max(m1.w, m2.w))

==(m1::Measure, m2::Measure)::Bool = m1.h == m2.h && m1.w == m2.w

"""
    width

Measure the width of renderable objects (text, AbsstractRenderable).
"""
width(x) = width(string(x))
width(x::AbstractString) = Measure(x).w

"""
    height

Measure the height of renderable objects (text, AbsstractRenderable).
"""
height(x) = height(string(x))
height(x::AbstractString) = Measure(x).h

Base.size(m::Measure) = (m.h, m.w)

end
