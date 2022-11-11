module Renderables

import Term:
    split_lines,
    reshape_text,
    ltrim_str,
    fillin,
    join_lines,
    unescape_brackets_with_space,
    DEBUG_ON,
    textwidth,
    str_trunc,
    text_to_width,
    get_bg_color,
    textlen

import Term: highlight as highlighter
import ..Consoles: console_width
import ..Measures: Measure
import ..Measures: width as get_width
import ..Segments: Segment
import ..Style: apply_style, MarkupStyle, get_style_codes

export AbstractRenderable, Renderable, RenderableText

# ------------------------------- abstract type ------------------------------ #

"""
    AbstractRenderable
"""
abstract type AbstractRenderable end

Measure(renderable::AbstractRenderable) = renderable.measure

info(r::AbstractRenderable)::String =
    "\e[38;5;117m$(typeof(r)) <: AbstractRenderable\e[0m \e[2m(h:$(r.measure.h), w:$(r.measure.w))\e[0m"

"""
    Base.string(r::AbstractRenderable)::String

Creates a string representation of a renderable
"""
Base.string(r::AbstractRenderable)::String = return if isnothing(r.segments)
    ""
else
    join([seg.text for seg in r.segments], "\n")
end

function Base.string(renderable::AbstractRenderable, width::Int)::String
    isnothing(renderable.measure) && return string(renderable)
    return if renderable.measure.w <= width
        string(renderable)
    else
        # string(trim_renderable(renderable, width)) * "\e[0m"
        string(RenderableText(string(renderable), width = width))
    end
end

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
    println(io, string(renderable))
    DEBUG_ON[] && println(io, info(renderable))
end

# -------------------------------- union type -------------------------------- #
RenderablesUnion = Union{AbstractString,AbstractRenderable}

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
Renderable(str::AbstractString) = RenderableText(str)

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

The text is resized to fit the given width.
Optionally `justify`  can be used to set the text justification style ∈ (:left, :center, :right, :justify).
"""
function RenderableText(
    text::AbstractString;
    style::Union{Nothing,String} = nothing,
    width::Int = min(Measure(text).w, console_width(stdout)),
    background::Union{Nothing,String} = nothing,
    justify::Symbol = :left,
)
    # @info "Construcing RenderableText" text width 
    # reshape text
    text = apply_style(text)
    text = text_to_width(text, width, justify; background = background) |> chomp

    style = isnothing(style) ? "" : style
    background = isnothing(background) ? "" : get_bg_color(background)
    style = style * background

    style_init, style_finish = get_style_codes(MarkupStyle(style))

    segments = map(ln -> Segment(style_init * ln * style_finish), split(text, "\n"))

    return RenderableText(segments, Measure(segments), style)
end

"""
    RenderableText(rt::RenderableText; width::Union{Nothing,Int} = nothing)

Construct a RenderableText by possibly re-shaping a RenderableText
"""
function RenderableText(
    rt::RenderableText;
    style::Union{Nothing,String} = nothing,
    width::Int = console_width(),
)
    return if rt.style == style && rt.measure.w == width
        rt
    else
        text = join_lines([seg.text for seg in rt.segments])
        RenderableText(text; style = style, width = width)
    end
end

# ---------------------------------------------------------------------------- #
#                                     MISC.                                    #
# ---------------------------------------------------------------------------- #

"""
    trim_renderable(ren::Union{String, AbstractRenderable}, width::Int)

Trim a string or renderable to a max width.
"""
function trim_renderable(ren::AbstractRenderable, width::Int)::AbstractRenderable
    # @info "Trimming renderable" ren
    text = getfield.(ren.segments, :text)
    segs = Segment.(map(s -> get_width(s) > width ? str_trunc(s, width) : s, text))
    return Renderable(segs, Measure(segs))
end

function trim_renderable(ren::RenderableText, width::Int)::RenderableText
    # @info "Trimming text renderable" ren
    text = join(getfield.(ren.segments, :text))
    return RenderableText(text, width = width)
end

trim_renderable(text::AbstractString, width::Int) = begin
    # @info "Trimming text" text
    text_to_width(text, width)
end

end
