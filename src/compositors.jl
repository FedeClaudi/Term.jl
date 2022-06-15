module Compositors

import MyterialColors: Palette, blue, pink

using ..Layout
import ..Layout: PlaceHolder
import ..Measures: width, height
import ..Renderables: AbstractRenderable, RenderableText, Renderable
import ..Repr: @with_repr, termshow
import Term: highlight, update!

export Compositor

include("_compositor.jl")

"""
    mutable struct LayoutElement
        id::Symbol
        w::Int
        h::Int
        renderable::Union{Nothing,String,AbstractRenderable}
        placeholder::PlaceHolder
    end

Stores a refence to an element of a `Compositor` layout.
Rendering a `Compositor` renders the renderable associated with 
each `LayoutElement` if there is one, the placeholder otherwise.
"""
@with_repr mutable struct LayoutElement
    id::Symbol
    w::Int
    h::Int
    renderable::Union{Nothing,String,AbstractRenderable}
    placeholder::PlaceHolder
end


"""
    mutable struct Compositor
        layout::Expr
        elements::Dict{Symbol,LayoutElement}
    end

A layout compositor, creates an updatable layout from an expression.
"""
mutable struct Compositor
    layout::Expr
    elements::Dict{Symbol,LayoutElement}
end

"""
    Compositor(layout::Expr; hpad::Int = 0, vpad::Int = 0, kwargs...)

Constructor. Parses a layout expression and creates LayoutElements for 
each element in the expression.
"""
function Compositor(layout::Expr; hpad::Int = 0, vpad::Int = 0, kwargs...)
    # get elements names and sizes
    elements = collect_elements(layout)
    elements = elements isa Expr ? parse_single_element_layout(elements) : elements

    # create renderables
    colors = if length(elements) > 1
        getfield.(Palette(blue, pink; N = length(elements)).colors, :string)
    else
        [pink]
    end

    renderables = Dict(
        s.args[1] => extract_renderable_from_kwargs(s.args...; kwargs...) for s in elements
    )

    placeholders =
        Dict(s.args[1] => placeholder(s.args..., c) for (c, s) in zip(colors, elements))

    # craete layout elements
    layout_elements = Dict(
        s.args[1] => LayoutElement(
            s.args[1],
            s.args[2],
            s.args[3],
            renderables[s.args[1]],
            placeholders[s.args[1]],
        ) for s in elements
    )

    # edit layout expression to add padding and remove size info
    expr = string(clean_layout_expr(copy(layout)))

    hpad > 0 && (expr = replace(expr, "* " => "* Spacer($hpad, 1) * "))

    vpad > 0 && (expr = replace(expr, "/" => "/ Spacer(1, $vpad) / "))

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
        @warn highlight("Could not update compsitor - id: `$id` is not in the layout")
        return
    end

    # check that the shapes match
    elem = compositor.elements[id]
    if elem.w != width(content) || elem.h != height(content)
        content_shape = "{red}$(width(content)) × $(height(content)){/red}"
        target_shape = "{bright_blue}$(elem.w) × $(elem.h){/bright_blue}"
        @warn "Shape mismatch while updating compositor element {yellow}`$id`{/yellow}.\nGot $content_shape, expected $target_shape"
    end

    # update content
    compositor.elements[id].renderable = content
end

update!(compositor::Compositor; kwargs) = map(
    (id, content) -> update!(compositor, id, content),
    kwargs
)

# ---------------------------------------------------------------------------- #
#                                   rendering                                  #
# ---------------------------------------------------------------------------- #
"""
    render(compositor::Compositor; show_placeholders = false)

Render a compositor's current layout. 

Get a renderable from each `LayoutElement` in the compositor
and evaluate the layout expression interpolating the renderables.
"""
function render(compositor::Compositor; show_placeholders = false)
    # evaluate compositor
    elements = getfield.(values(compositor.elements), :id)
    renderables = getfield.(values(compositor.elements), :renderable)
    placeholders = getfield.(values(compositor.elements), :placeholder)
    length(renderables) == 1 &&
        return isnothing(renderables[1]) ? placeholders[1] : renderables[1]

    components = if show_placeholders
        Dict(e => p for (e, p) in zip(elements, placeholders))
    else
        Dict(
            e => isnothing(r) ? p : r for
            (e, r, p) in zip(elements, renderables, placeholders)
        )
    end
    ex = interpolate_from_dict(compositor.layout, components)

    # insert padding
    return eval(:(a = $ex))
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
