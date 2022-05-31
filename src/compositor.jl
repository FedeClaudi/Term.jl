module Compositors

import MyterialColors: Palette, blue, pink

using ..Layout
import ..Measures: width, height
import ..Renderables: AbstractRenderable, RenderableText
import ..Repr: @with_repr, termshow
import Term: highlight

export Compositor


include("_compositor.jl")

@with_repr mutable struct LayoutElement
    id::Symbol
    w::Int
    h::Int
    renderable::Union{String, AbstractRenderable}
end
@with_repr mutable struct Compositor
    layout::Expr
    elements::Dict{Symbol, LayoutElement}
end

function renderable_or_placeholder(s, w, h, c; kwargs...)
    ren = get(kwargs, s, nothing)
    if isnothing(ren)
        ren = PlaceHolder(
            w, h; style=c, text=string(s), 
        ) 
    else
        ren = ren isa AbstractRenderable ? ren : RenderableText(ren)
        msg = "While creating a Compository layout, the layout element"

        @assert ren.measure.w == w highlight(msg * " :$s has width $w but the renderable passed has width $(ren.measure.w)")
        @assert ren.measure.h == h highlight(msg * " :$s has height $h but the renderable passed has height $(ren.measure.h)")
    end
    return ren
end

function Compositor(layout::Expr; hpad::Int=0, vpad::Int=0, kwargs...)
    # get elements names and sizes
    elements = collect_elements(layout)

    # create renderables
    if length(elements) > 1
        colors = getfield.(Palette(blue, pink; N=length(elements)).colors, :string)
    else
        colors = [pink]
    end
    renderables = Dict(
            s.args[1]=>renderable_or_placeholder(s.args..., c; kwargs...)
            for (c,s) in zip(colors, elements)
    )

    # craete layout elements
    layout_elements = Dict(
        s.args[1] => LayoutElement(
            s.args[1], s.args[2], s.args[3], renderables[s.args[1]],
        ) for s in elements
    )

    # edit layout expression to add padding and remove size info
    expr = string(clean_layout_expr(layout))
    expr = replace(expr, "*" => "* Spacer($hpad, 1) * ")
    expr = replace(expr, "/" => "/ Spacer(1, $vpad) / ")
    expr = Meta.parse(expr)

    return Compositor(expr, layout_elements)
end


function render(compositor::Compositor)
    # evaluate compositor
    elements = getfield.(values(compositor.elements), :id)
    renderables = getfield.(values(compositor.elements), :renderable)

    components = Dict(e => r for (e,r) in zip(elements, renderables))
    ex = interpolate_from_dict(compositor.layout, components)

    # insert padding
    return eval(:(a = $ex))
end

Base.string(compositor::Compositor) = string(render(compositor))

function Base.print(io::IO, compositor::Compositor; highlight = true)
    return println(io, string(compositor))
end





end