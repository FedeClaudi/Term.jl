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
    str_trunc

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
Base.string(r::AbstractRenderable)::String = join([seg.text for seg in r.segments], "\n")

function Base.string(renderable::AbstractRenderable, width::Int)::String 
    return if renderable.measure.w <= width
        string(renderable)
    else
        string(trim_renderable(renderable, width))
    end
end

"""
    print(io::IO, renderable::AbstractRenderable)

Print a renderable to an IO
"""
function Base.print(io::IO, renderable::AbstractRenderable; highlight = true)
    ren = unescape_brackets_with_space(string(renderable, console_width(io)))
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
    println(io, string(renderable, console_width(io)))
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

If a `width` is passed the text is resized to match the width.
"""
function RenderableText(
    text::AbstractString;
    style::Union{Nothing,String} = nothing,
    width::Int = min(textwidth(text), console_width()),
    background::Union{Nothing,String} = nothing,
)
    text = apply_style(text)

    # reshape text
    if !isnothing(width)
        width = min(console_width(stdout) - 1, width)
        text = reshape_text(text, width)
    end
    text = fillin(text, bg = background)

    # create renderable
    segments = if isnothing(style)
        Segment.(
            isnothing(width) ? split_lines(text) :
            map(ln -> rpad(ln, width - textwidth(ln) + 1), split_lines(text))
        )
    else
        style_init, style_finish = get_style_codes(MarkupStyle(style))
        map(ln -> Segment(style_init * ln * style_finish), split_lines(text))
    end

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
function trim_renderable(ren::AbstractRenderable, width::Int)::Renderable
    text = getfield.(ren.segments, :text)

    return if ren isa RenderableText
        /(reshape_text.(text, width)...)
    else
        # @info "trimming ren" ren.measure width text
        segs = map(
            s -> get_width(s) > width ? str_trunc(s, width) : s,
            text,
        )
        /(segs...)
    end

end

trim_renderable(ren::AbstractString, width::Int)::String = begin
    reshape_text(ren, width)
end


end
