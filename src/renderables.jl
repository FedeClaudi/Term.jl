module renderables

import ..measure: Measure
import ..segment: Segment
import ..console: console_width
import ..style: get_style_codes, MarkupStyle
import Term: split_lines, reshape_text, fillin, join_lines

export AbstractRenderable, Renderable, RenderableText

# ------------------------------- abstract type ------------------------------ #

"""
    AbstractRenderable
"""
abstract type AbstractRenderable end

Measure(renderable::AbstractRenderable) = renderable.measure


"""
    Base.string(r::AbstractRenderable)::String

Creates a string representation of a renderable
"""
function Base.string(r::AbstractRenderable)::String
    lines = [seg.text for seg in r.segments]
    return join(lines, "\n")
end

function Base.show(io::IO, renderable::AbstractRenderable)
    if io == stdout
        for seg in renderable.segments
            println(io, seg)
        end
    else
        print(
            io,
            "$(typeof(renderable)) <: AbstractRenderable \e[2msize: $(renderable.measure)\e[0m",
        )
    end
end

# ------------------------- generic renderable object ------------------------ #

"""
    Renderable

Generic `Renderable` object.
"""

struct Renderable <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
end


"""
    Renderable(
        str::String; width::Union{Nothing,Int} = nothing
    )

Convenience method to construct a RenderableText
"""
function Renderable(
    str::AbstractString; width::Union{Nothing,Int} = nothing
)
    return RenderableText(str; width = width)
end

Renderable(ren::AbstractRenderable) = ren
Renderable() = Renderable(Vector{Segment}[], Measure(0, 0))

# ---------------------------------------------------------------------------- #
#                                TEXT RENDERABLE                               #
# ---------------------------------------------------------------------------- #

"""
    RenderableText

`Renderable` represnting a text.

See also [`Renderable`](@ref), [`TextBox`](@ref)
"""

struct RenderableText <: AbstractRenderable
    segments::Vector
    measure::Measure
    style::Union{Nothing, String}
end

"""
    RenderableText(text::String; width::Union{Nothing, Int, Symbol}=nothing)

Construct a `RenderableText` out of a string.

If a `width` is passed the text is resized to match the width.
"""
function RenderableText(text::AbstractString; style::Union{Nothing, String}=nothing, width::Union{Nothing,Int} = nothing)
    # reshape text
    if !isnothing(width)
        width = min(console_width(stdout)-1, width)
        text = reshape_text(text, width)
    end
    text = fillin(text)

    # create renderable
    if isnothing(style)
        segments = Segment.(split_lines(text))
    else
        style_init, style_finish = get_style_codes(MarkupStyle(style))
        segments = map(ln -> Segment(style_init * ln * style_finish), split_lines(text))
    end

    return RenderableText(segments, Measure(segments), style)
end

"""
    RenderableText(rt::RenderableText; width::Union{Nothing,Int} = nothing)

Construct a RenderableText by possibly re-shaping a RenderableText
"""
function RenderableText(rt::RenderableText; style::Union{Nothing, String}=nothing, width::Union{Nothing,Int} = nothing)
    if rt.style == style && rt.measure.w == width
        return rt
    else
        text = join_lines([seg.text for seg in rt.segments])
        return RenderableText(text; style=style, width=width)   
    end
end

"""
    RenderableText(text::Vector; width::Union{Nothing,Int} = nothing)

Construct a RenderableText out a vector of objects.
"""
function RenderableText(text::Vector; style::Union{Nothing, String}=nothing, width::Union{Nothing,Int} = nothing)
    return RenderableText(join(string(text), "\n"); style=style, width = width)
end



# -------------------------------- union type -------------------------------- #
RenderablesUnion = Union{AbstractString,AbstractRenderable}

end
