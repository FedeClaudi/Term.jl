module measure

import Term: remove_ansi, remove_markup_open, remove_markup

export Measure

"""
    Measure

Stores the size of a piece of renderable material
"""
mutable struct Measure
    w::Int
    h::Int
end

Base.show(io::IO, M::Measure) = print(io, "Measure (w: $(M.w), h: $(M.h))")

"""
    Measure(str::String)

Constructs a measure object from a string
"""
function Measure(str::AbstractString)
    str = (remove_ansi ∘ remove_markup_open ∘ remove_markup)(str)
    lines = split(str, "\n")
    w = max([textwidth(ln) for ln in lines]...)
    return Measure(w, length(lines))
end

"""
The sum of measures returns a measure with the highest value along each dimension
"""
Base.:+(m1::Measure, m2::Measure)::Measure = Measure(max(m1.w, m2.w), m1.h + m2.h)

"""
    width

Measure the width of renderable objects (text, AbsstractRenderable)
"""
function width end


"""
    height

Measure the height of renderable objects (text, AbsstractRenderable)
"""
function height end




end
