module Compositors

import MyterialColors: Palette, blue, pink

using ..Layout
import ..Layout: PlaceHolder
import ..Measures: width, height, default_size
import ..Renderables: AbstractRenderable, RenderableText, Renderable
import ..Repr: @with_repr, termshow
import ..Consoles: console_height, console_width
import Term: highlight, update!, fint

export Compositor

include("_compositor.jl")

"""
    mutable struct LayoutElement
        id::Symbol
        h::Int
        w::Int
        renderable::Union{Nothing,String,AbstractRenderable}
        placeholder::PlaceHolder
    end

Stores a refence to an element of a `Compositor` layout.
Rendering a `Compositor` renders the renderable associated with 
each `LayoutElement` if there is one, the placeholder otherwise.
"""

@with_repr mutable struct LayoutElement
    id::Symbol
    h::Int
    w::Int
    renderable::Union{Nothing,String,AbstractRenderable}
    placeholder::PlaceHolder

    function LayoutElement(
        id::Symbol,
        h::Number,
        w::Number,
        renderable::Union{Nothing,String,AbstractRenderable},
        placeholder::PlaceHolder;
        max_w::Int = console_width(),
        max_h::Int = console_height(),
    )
        h = h isa Int ? h : fint(max_h * h)
        w = w isa Int ? w : fint(max_w * w)
        return new(id, h, w, renderable, placeholder)
    end
end

Base.size(e::LayoutElement) = (e.h, e.w)

"""
    mutable struct Compositor
        layout::Expr
        elements::Dict{Symbol,LayoutElement}
    end

A layout compositor, creates an updatable layout from an expression.
"""
mutable struct Compositor
    layout::Expr
    elements::Dict{Symbol,Union{Nothing,LayoutElement}}
end

"""
    Compositor(layout::Expr; hpad::Int = 0, vpad::Int = 0, check::Bool = true, kwargs...)

Constructor. Parses a layout expression and creates LayoutElements for 
each element in the expression.
"""
function Compositor(
    layout::Expr;
    hpad::Int = 0,
    vpad::Int = 0,
    placeholder_size = nothing,
    check::Bool = true,
    max_w::Int = console_width(),
    max_h::Int = console_height(),
    kwargs...,
)
    elements = get_elements_and_sizes(layout; placeholder_size = placeholder_size)
    names = map(e -> first(e.args), elements)

    # create renderables
    colors = if length(elements) > 1
        getfield.(Palette(blue, pink; N = length(elements)).colors, :string)
    else
        [pink]
    end

    renderables = Dict(
        n => extract_renderable_from_kwargs(e.args...; check = check, kwargs...) for
        (n, e) in zip(names, elements)
    )

    placeholders = Dict(
        n => compositor_placeholder(e.args..., n ≡ :_ ? "hidden" : c) for
        (n, c, e) in zip(names, colors, elements)
    )

    # create layout elements
    layout_elements = Dict(
        n => LayoutElement(
            n,          # symbol
            e.args[2],  # height
            e.args[3],  # width
            renderables[n],
            placeholders[n];
            max_w = max_w,
            max_h = max_h,
        ) for (n, e) in zip(names, elements)
    )

    # edit layout expression to add padding and remove size info
    expr = string(clean_layout_expr(copy(layout)))

    hpad > 0 && (expr = replace(expr, "*" => "* Spacer(1, $hpad) *"))
    vpad > 0 && (expr = replace(expr, "/" => "/ Spacer($vpad, 1) /"))

    expr = Meta.parse(expr)

    # handle the edge case with a single element
    expr = expr isa Expr ? expr : Expr(:call, expr)

    return Compositor(expr, layout_elements)
end

Renderable(compositor::Compositor) = Renderable(string(compositor))

# ---------------------------------- update ---------------------------------- #
"""
    function update!(
        compositor::Compositor,
        id::Symbol,
        content::Union{String,AbstractRenderable},
    )

Update a `LayoutElement` in a `Compositor` with new content.
If the content's measure doesn't match the pre-defined size of 
the `LayoutElement`, it prints a warning message.
"""
function update!(
    compositor::Compositor,
    id::Symbol,
    content::Union{String,AbstractRenderable},
)
    # check that the id is valid
    haskey(compositor.elements, id) || begin
        @warn highlight("Could not update compositor - id: `$id` is not in the layout")
        return
    end

    # if content is too small, pad it
    elem = compositor.elements[id]
    height(content) < elem.h &&
        (content = vertical_pad(content; height = elem.h, method = :top))
    width(content) < elem.w && (content = pad(content; width = elem.w, method = :right))

    # check that the shapes match
    if elem.w > width(content) || elem.h > height(content)
        content_shape = "{red}$(height(content)) × $(width(content)){/red}"
        target_shape = "{bright_blue}$(elem.h) × $(elem.w){/bright_blue}"
        @warn "Shape mismatch while updating compositor element {yellow}`$id`{/yellow}.\nGot $content_shape, expected $target_shape"
    end

    # update content
    compositor.elements[id].renderable = content
end

function update!(compositor::Compositor; kwargs...)
    for (id, content) in kwargs
        update!(compositor, id, content)
    end
    compositor
end

# ---------------------------------------------------------------------------- #
#                                   rendering                                  #
# ---------------------------------------------------------------------------- #
"""
    render(compositor::Compositor; show_placeholders = false)

Render a compositor's current layout. 

Get a renderable from each `LayoutElement` in the compositor
and evaluate the layout expression interpolating the renderables.
"""
function render(compositor::Compositor; show_placeholders = false)::AbstractRenderable
    # evaluate compositor
    elements = getfield.(values(compositor.elements), :id)
    renderables = getfield.(values(compositor.elements), :renderable)
    placeholders = getfield.(values(compositor.elements), :placeholder)
    length(renderables) == 1 && return something(renderables[1], placeholders[1])

    components = if show_placeholders
        Dict(zip(elements, placeholders))
    else
        Dict(e => something(r, p) for (e, r, p) in zip(elements, renderables, placeholders))
    end
    return eval(interpolate_from_dict(compositor.layout, components))
end

Base.string(compositor::Compositor; kwargs...) = string(render(compositor; kwargs...))

Base.print(io::IO, compositor::Compositor; highlight = true, kwargs...) =
    println(io, string(compositor; kwargs...))

Base.print(compositor::Compositor; kwargs...) = Base.print(stdout, compositor; kwargs...)

"""
Base.show(io::IO, ::MIME"text/plain", compositor::Compositor)

Show a compositor.
"""
Base.show(io::IO, ::MIME"text/plain", compositor::Compositor) =
    println(io, string(compositor))

end
