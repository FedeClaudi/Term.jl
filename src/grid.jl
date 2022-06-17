"""
Author(s): T Bltg (github.com/t-bltg)
"""
module Grid

import ..Renderables: Renderable, AbstractRenderable
import ..Measures: Measure, default_size, height, width
import ..Layout: PlaceHolder, vstack
import ..Compositors: Compositor

import Term: calc_nrows_ncols

export grid

include("_compositor.jl")

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
creates placeholders. Complex layout is supported using compositor expressions.
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

    ph_style = show_placeholder ? "" : "hidden"

    if !isnothing(rens) && layout isa Expr
        n, kw = 0, Dict()
        sizes = size.(rens)
        # arbitrary, taking the smallest `Renderable` size for placeholder
        ph_size = (minimum(first.(sizes)), minimum(last.(sizes)))

        for (i, e) in enumerate(get_elements_and_sizes(layout; placeholder_size = ph_size))
            kw[(nm = e.args[1])] = if nm === :_
                compositor_placeholder(nm, ph_size..., ph_style)
            else
                haskey(kw, nm) ? kw[nm] : rens[n += 1]
            end
        end
        compositor =
            Compositor(layout; placeholder_size = ph_size, check = false, pairs(kw)...)
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
        fill_in = something(placeholder, PlaceHolder(first(rens); style = ph_style))
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
