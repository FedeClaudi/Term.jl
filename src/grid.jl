module Grid

import ..Renderables: Renderable, AbstractRenderable
import ..Measures: Measure, default_size, height, width
import ..Layout: PlaceHolder, vstack
import ..Compositors: Compositor

import Term: calc_nrows_ncols

export grid

include("_compositor.jl")

# ---------------------------------------------------------------------------- #
#                                     GRID                                     #
# ---------------------------------------------------------------------------- #

"""
    grid(
        rens::Union{Nothing,AbstractVector{<:AbstractRenderable}} = nothing;
        placeholder::Union{Nothing,AbstractRenderable} = nothing,
        aspect::Union{Nothing,Number,NTuple} = nothing,
        layout::Union{Nothing,Tuple} = nothing, 
        pad::Union{Tuple,Integer} = 0,
    )

Construct a grid from a `AbstractVector` of `AbstractRenderable`s.

Lays out the renderables to createa a grid with the desired aspect ratio or
layout (number of rows, number of columns). If no renderables are passed it
creates placeholders.
"""
function grid(
    rens::Union{Nothing,AbstractVector{<:AbstractRenderable}} = nothing;
    placeholder::Union{Nothing,AbstractRenderable} = nothing,
    aspect::Union{Nothing,Number,NTuple} = nothing,
    layout::Union{Nothing,Tuple,Expr} = nothing,
    show_placeholder::Bool = false,
    pad::Union{Tuple,Integer} = 0,
)
    (isnothing(layout) && isnothing(rens)) && error("Grid: layout or aspect required")

    style = show_placeholder ? "" : "hidden"

    if !isnothing(rens) && layout isa Expr
        n, kw = 0, Dict()
        sizes = size.(rens)
        sz = (minimum(first.(sizes)), minimum(last.(sizes)))
        for (i, e) in enumerate(get_elements_and_sizes(layout; placeholder_size = sz))
            nm = e.args[1]
            kw[nm] = if nm === :_
                compositor_placeholder(nm, sz..., style)
            else
                rens[n += 1]
            end
        end
        compositor = Compositor(layout; placeholder_size = sz, check = false, pairs(kw)...)
        return Renderable(compositor)
    end

    nrows, ncols = isnothing(layout) ? calc_nrows_ncols(length(rens), aspect) : layout
    if isnothing(rens)
        isnothing(layout) &&
            throw(ArgumentError("`layout` must be given as `Tuple` of `Integer`s"))
        rens = fill(PlaceHolder(default_size()...), prod(layout))
    else
        if isnothing(nrows)
            nrows, r = divrem(length(rens), ncols)
            r == 0 || (nrows += 1)
        elseif isnothing(ncols)
            ncols, r = divrem(length(rens), nrows)
            r == 0 || (ncols += 1)
        end
        fill_in =
            (isnothing(placeholder) ? PlaceHolder(first(rens); style = style) : placeholder)
        rens = vcat(rens, repeat([fill_in], nrows * ncols - length(rens)))
    end
    return grid(reshape(rens, nrows, ncols); pad = pad)
end

"""
    grid(rens::AbstractMatrix{<:AbstractRenderable}; pad::Union{Nothing,Integer} = 0))

Construct a grid from a `AbstractMatrix` of `AbstractRenderable`s.
"""
function grid(rens::AbstractMatrix{<:AbstractRenderable}; pad::Union{Tuple,Integer} = 0)
    hpad, vpad = if pad isa Integer
        (pad, pad)
    else
        pad
    end
    rows = collect(
        foldl((a, b) -> a * ' '^hpad * b, col[2:end]; init = first(col)) for
        col in eachrow(rens)
    )
    if vpad > 0
        vspace = vpad > 1 ? vstack(repeat([" "], vpad)...) : " "
        cat = (a, b) -> a / vspace / b
    else
        cat = (a, b) -> a / b
    end
    return foldl(cat, rows[2:end]; init = first(rows))
end

end
