module Measures

import Term: rint, remove_ansi, remove_markup, DEFAULT_WT, DEFAULT_AR

export Measure

"""
    Measure

Stores the size of a piece of renderable material.
"""
mutable struct Measure
    w::Int
    h::Int
end

Base.show(io::IO, M::Measure) = print(io, "Measure (w: $(M.w), h: $(M.h))")

"""
    default_size()

Returns default size (w, h).
"""
default_size() = (DEFAULT_WT[], rint(DEFAULT_WT[] / 2DEFAULT_AR[]))

"""
    Measure(str::String)

Constructs a measure object from a string
"""
function Measure(str::AbstractString)
    str = (remove_ansi ∘ remove_markup)(str)
    lines = split(str, "\n")
    w = max([textwidth(ln) for ln in lines]...)
    return Measure(w, length(lines))
end

"""
The sum of measures returns a measure with the highest value along each dimension.
"""
Base.:+(m1::Measure, m2::Measure)::Measure = Measure(max(m1.w, m2.w), m1.h + m2.h)

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

Base.size(m::Measure) = (m.w, m.h)

end
