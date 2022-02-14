
"""
    Measure

Stores the size of a piece of renderable material
"""
struct Measure
    w::Int
    h::Int
end

Base.show(io::IO, M::Measure) = print(io, "Measure (w: $(M.w), h: $(M.h))")

function Measure(str::String)
    lines = split(str, "\n")
    w = max([length(ln) for ln in lines]...)
    return Measure(w, length(lines))
end

