module renderables

import ..measure: Measure
import ..segment: Segment
import ..consoles: console_width
import Term: split_lines, reshape_text, do_by_line

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
mutable struct Renderable <: AbstractRenderable
    segments::Vector
    measure::Measure
end

Renderable() = Renderable([], Measure(0, 0))
function Renderable(
    str::Union{Vector,AbstractString}; width::Union{Nothing,Int} = nothing
)
    return RenderableText(str; width = width)
end
Renderable(ren::AbstractRenderable; width::Union{Nothing,Int,Symbol} = nothing) = ren  # returns the renderable
function Renderable(segment::Segment; width::Union{Nothing,Int,Symbol} = nothing)
    return Renderable([segment], Measure([segment]))
end

# ---------------------------------------------------------------------------- #
#                                TEXT RENDERABLE                               #
# ---------------------------------------------------------------------------- #

"""
    RenderableText

`Renderable` represnting a text.

See also [`Renderable`](@ref), [`TextBox`](@ref)
"""
mutable struct RenderableText <: AbstractRenderable
    segments::Vector
    measure::Measure
    text::AbstractString
end

"""
    RenderableText(text::AbstractString; width::Union{Nothing, Int, Symbol}=nothing)

Construct a `RenderableText` out of a string.

If a `width` is passed the text is resized to match the width.
"""
function RenderableText(text::AbstractString, style="default"; width::Union{Nothing,Int} = nothing)
    width = isnothing(width) ? console_width(stdout) : width
    if width isa Number
        width = min(console_width(stdout), width)
        text = do_by_line((ln) -> reshape_text(ln, width), text)
    end

    segments = [Segment(line, style) for line in split_lines(chomp(text))]
    return RenderableText(segments, Measure(segments), text)
end

"""
    RenderableText(rt::RenderableText; width::Union{Nothing,Int} = nothing)

Construct a RenderableText by possibly re-shaping a RenderableText
"""
RenderableText(rt::RenderableText, style="default"; width::Union{Nothing,Int} = nothing) = RenderableText(chomp(replace(rt.text, "\n"=>"")), style; width=width)

"""
    RenderableText(text::Vector; width::Union{Nothing,Int} = nothing)

Construct a RenderableText out a vector of objects.
"""
function RenderableText(text::Vector, style="default"; width::Union{Nothing,Int} = nothing)
    return RenderableText(join(string(text), "\n"), style; width = width)
end



# -------------------------------- union type -------------------------------- #
RenderablesUnion = Union{AbstractString,AbstractRenderable,RenderableText}

end
