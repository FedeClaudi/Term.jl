module Renderables

import Term:
    split_lines,
    reshape_text,
    ltrim_str,
    fillin,
    join_lines,
    unescape_brackets_with_space,
    TERM_DEBUG_ON

import ..Style: get_style_codes, MarkupStyle, apply_style
import Term: highlight as highlighter
import ..Consoles: console_width
import ..Measures: Measure
import ..Segments: Segment

export AbstractRenderable, Renderable, RenderableText

# ------------------------------- abstract type ------------------------------ #

"""
    AbstractRenderable
"""
abstract type AbstractRenderable end

Measure(renderable::AbstractRenderable) = renderable.measure

info(r::AbstractRenderable)::String =
    "\e[38;5;117m$(typeof(r)) <: AbstractRenderable\e[0m \e[2m(w:$(r.measure.w), h:$(r.measure.h))\e[0m"

"""
    Base.string(r::AbstractRenderable)::String

Creates a string representation of a renderable
"""
Base.string(r::AbstractRenderable)::String = join([seg.text for seg in r.segments], "\n")

"""
    print(io::IO, renderable::AbstractRenderable)

Print a renderable to an IO
"""
function Base.print(io::IO, renderable::AbstractRenderable; highlight = true)
    ren = unescape_brackets_with_space(string(renderable))
    return println(io, ren)
end

"""
    show(io::IO, renderable::AbstractRenderable)

Show a renderable.
"""
Base.show(io::IO, renderable::AbstractRenderable) = print(io, info(renderable))

"""
    show(io::IO, mime::MIME"text/plain", renderable::AbstractRenderable)

Show a renderable and some information about its shape.
"""
function Base.show(io::IO, ::MIME"text/plain", renderable::AbstractRenderable)
    if TERM_DEBUG_ON[]
        println(io, string(renderable))
        println(io, info(renderable))
    else
        print(io, string(renderable))
    end
end

# ------------------------- generic renderable object ------------------------ #

"""
    Renderable

Generic `Renderable` object.
"""

mutable struct Renderable <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
end

Base.convert(::Renderable, x) = Renderable(x)

"""
    Renderable(
        str::String; width::Union{Nothing,Int} = nothing
    )

Convenience method to construct a RenderableText
"""
function Renderable(str::AbstractString; width::Union{Nothing,Int} = nothing)
    return RenderableText(str; width = width)
end

Renderable(ren::AbstractRenderable) = ren
Renderable() = Renderable(Vector{Segment}[], Measure(0, 0))

# ---------------------------------------------------------------------------- #
#                                TEXT RENDERABLE                               #
# ---------------------------------------------------------------------------- #

"""
    RenderableText

`Renderable` representing a text.

See also [`Renderable`](@ref), [`TextBox`](@ref)
"""

mutable struct RenderableText <: AbstractRenderable
    segments::Vector
    measure::Measure
    style::Union{Nothing,String}
end

"""
    RenderableText(text::String; width::Union{Nothing, Int, Symbol}=nothing)

Construct a `RenderableText` out of a string.

If a `width` is passed the text is resized to match the width.
"""
function RenderableText(
    text::AbstractString;
    style::Union{Nothing,String} = nothing,
    width::Union{Nothing,Int} = nothing,
)
    text = apply_style(text)

    # reshape text
    if !isnothing(width)
        width = min(console_width(stdout) - 1, width)
        text = reshape_text(text, width)
    end
    text = fillin(text)

    # create renderable
    if isnothing(style)
        segments = if !isnothing(width)
            Segment.(map(ln -> rpad(ln, width - textwidth(ln) + 1), split_lines(text)))

        else
            Segment.(split_lines(text))
        end
    else
        style_init, style_finish = get_style_codes(MarkupStyle(style))
        segments = map(ln -> Segment(style_init * ln * style_finish), split_lines(text))
    end

    # @info "a" Measure(segments) segments[1]

    return RenderableText(segments, Measure(segments), style)
end

"""
    RenderableText(rt::RenderableText; width::Union{Nothing,Int} = nothing)

Construct a RenderableText by possibly re-shaping a RenderableText
"""
function RenderableText(
    rt::RenderableText;
    style::Union{Nothing,String} = nothing,
    width::Union{Nothing,Int} = nothing,
)
    if rt.style == style && rt.measure.w == width
        return rt
    else
        text = join_lines([seg.text for seg in rt.segments])
        return RenderableText(text; style = style, width = width)
    end
end

# -------------------------------- union type -------------------------------- #
RenderablesUnion = Union{AbstractString,AbstractRenderable}

end
