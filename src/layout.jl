module layout

import Parameters: @with_kw

import Term: int, get_last_valid_str_idx
import ..renderables: RenderablesUnion, Renderable, AbstractRenderable
import ..measure: Measure
import ..segment: Segment
using ..box
import ..consoles: console_width, console_height

export Padding, vstack, hstack, pad
export Spacer, vLine, hLine

# ---------------------------------------------------------------------------- #
#                                    PADDING                                   #
# ---------------------------------------------------------------------------- #
"""
    Padding

Stores information about ammount of padding.
"""
@with_kw struct Padding
    left::Int
    right::Int
    top::Int
    bottom::Int
end


"""
    pad(text::AbstractString, target_width::Int, method::Symbol)::String

Pad a string to width: `target_width` by adding empty spaces strings " ".
Where the spaces are added depends on the justification `method` ∈ (:left, :center, :right).
"""
function pad(text::AbstractString, target_width::Int, method::Symbol)::String
    # get total padding size
    lw = Measure(text).w
    if lw >= target_width
        return text
    end

    npads = target_width - lw

    if method == :left
        return text * " "^npads
    elseif method == :right
        return " "^npads * text
    else
        if npads % 2 == 0
            nl = nr = Int(npads/2)
        else
            nl = (Int ∘ floor)(npads/2)
            nr = nl + 1
        end
        return " "^nl * text * " "^nr
    end
end

"""
    pad(text::AbstractString, left::Int=0, right::Int=0)::String

Pad a string by a fixed ammount.
"""
function pad(text::AbstractString, left::Int=0, right::Int=0)::String
    return " "^left * text * " "^right
end

function pad(segments::Vector{Segment}, left::Int=0, right::Int=0)::Vector{Segment}
    return map(
        (s)->Segment(" "^left * s.text * " "^right),
        segments
    )
end

# ---------------------------------------------------------------------------- #
#                                   STACKING                                   #
# ---------------------------------------------------------------------------- #
"""
    vstack(r1::RenderablesUnion, r2::RenderablesUnion)

Vertically stack two renderables to give a new renderable.
"""
function vstack(r1::RenderablesUnion, r2::RenderablesUnion)
    r1 = Renderable(r1)
    r2 = Renderable(r2)

    # get dimensions of final renderable
    w1 = length(r1.segments) > 1 ? max([s.measure.w for s in r1.segments]...) : r1.measure.w
    w2 = length(r2.segments) > 1 ? max([s.measure.w for s in r2.segments]...) : r2.measure.w
    if w1 > w2
        s1 = r1.segments

        s2 = map(
            (s)->Segment(s.text * " ".^(w1-s.measure.w)),
            r2.segments
        )
    elseif w1 < w2
        s1 = map(
            (s)->Segment(s.text * " ".^(w2-s.measure.w)),
            r1.segments
        )
        s2 = r2.segments
    else
        s1, s2 = r1.segments, r2.segments
    end

    # create segments stack
    segments::Vector{Segment} = vcat(s1, s2)
    measure = Measure(max(w1, w2), length(segments))
    return Renderable(segments, measure)
end

""" 
    vstack(renderables...)

Vertically stack a variable number of renderables
"""
function vstack(renderables...)
    renderable = Renderable()

    for ren in renderables
        renderable = vstack(renderable, ren)
    end
    return renderable
end

"""
    hstack(r1::RenderablesUnion, r2::RenderablesUnion)

Horizontally stack two renderables to give a new renderable.
"""
function hstack(r1::RenderablesUnion, r2::RenderablesUnion)
    r1 = r1 isa AbstractRenderable ? r1 : Renderable(r1)
    r2 = r2 isa AbstractRenderable ? r2 : Renderable(r2)

    # get dimensions of final renderable
    h1 = r1.measure.h
    h2 = r2.measure.h
    # h1 = max([s.measure.w for s in r1.segments]...)
    # h2 = max([s.measure.w for s in r2.segments]...)
    Δh = abs(h2 - h1)

    # make sure both renderables have the same number of segments
    if h1 > h2
        s1 = r1.segments
        s2 = vcat(r2.segments, [Segment(" "^(r2.measure.w)) for i in 1:(Δh)])
    elseif h1 < h2
        s1 = vcat(r1.segments, [Segment(" "^(r1.measure.w)) for i in 1:(Δh)])
        s2 = r2.segments
    else
        s1, s2, = r1.segments, r2.segments
    end

    # combine segments
    segments = [Segment(s1.text * s2.text) for (s1, s2) in zip(s1, s2)]

    return Renderable(segments, Measure(r1.measure.w+r2.measure.w, max(r1.measure.h, r2.measure.h)))
end

""" 
    hstack(renderables...)

Horizonatlly stack a variable number of renderables
"""
function hstack(renderables...)
    renderable = Renderable()

    for ren in renderables
        renderable = hstack(renderable, ren)
    end
    return renderable
end

# --------------------------------- operators -------------------------------- #

"""
    Operators for more coincise layout of renderables
"""

Base.:/(r1::RenderablesUnion, r2::RenderablesUnion) = vstack(r1, r2)

Base.:*(r1::AbstractRenderable, r2::AbstractRenderable) = hstack(r1, r2)
Base.:*(r1::AbstractString, r2::AbstractRenderable) = hstack(r1, r2)
Base.:*(r1::AbstractRenderable, r2::AbstractString) = hstack(r1, r2)

# ---------------------------------------------------------------------------- #
#                                LINES & SPACER                                #
# ---------------------------------------------------------------------------- #
abstract type AbstractLayoutElement <: AbstractRenderable end

# ---------------------------------- spacer ---------------------------------- #
"""
        Spacer

A box of empty text with given width and height.
"""
mutable struct Spacer <: AbstractLayoutElement
    segments::Vector{Segment}
    measure::Measure
end

function Spacer(width::Number, height::Number; char::Char = ' ')
    width = int(width)
    height = int(height)

    line = char^width
    segments = [Segment(line) for i in 1:height]
    return Spacer(segments, Measure(segments))
end

# ----------------------------------- vline ---------------------------------- #
"""
    vLine

A multi-line renderable with each line made of a | to create a vertical line
"""
mutable struct vLine <: AbstractLayoutElement
    segments::Vector{Segment}
    measure::Measure
    height::Int
end

"""
    vLine(height::Number, style::Union{String, Nothing}; box::Symbol=:ROUNDED)

Create a `vLine` given a height and, optionally, style information.
"""
function vLine(
    height::Number; style::Union{String,Nothing} = nothing, box::Symbol = :ROUNDED
)
    height = int(height)
    char = string(eval(box).head.left)
    segments = [Segment(char, style) for i in 1:height]
    return vLine(segments, Measure(segments), height)
end

"""
    vLine(; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Create a `vLine` as tall as the `stdout` console
"""
function vLine(; style::Union{String,Nothing} = nothing, box::Symbol = :ROUNDED)
    return vLine(console_height(); style = style, box = box)
end

"""
    hLine

A 1-line renderable made of repeated character from a Box.
"""
mutable struct hLine <: AbstractLayoutElement
    segments::Vector{Segment}
    measure::Measure
    width::Int
end

"""
    hLine(width::Number, style::Union{String, Nothing}; box::Symbol=:ROUNDED)

Create a styled `hLine` of given width.
"""
function hLine(
    width::Number; style::Union{String,Nothing} = nothing, box::Symbol = :ROUNDED
)
    width = int(width)
    char = eval(box).row.mid
    segments = [Segment(char^width, style)]
    return hLine(segments, Measure(segments), width)
end

"""
    hLine(width::Number, text::String; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Creates an hLine object with texte centered horizontally.
"""
function hLine(
    width::Number,
    text::String;
    style::Union{String,Nothing} = nothing,
    box::Symbol = :ROUNDED,
)
    box = eval(box)

    initial_line = box.top.mid^width

    cutval = int(ncodeunits(initial_line) / 2 - ncodeunits(text) - 5)
    cut_start = get_last_valid_str_idx(initial_line, cutval)

    pre = Segment(
        Segment(initial_line[1:cut_start], style) *
        "\e[0m" *
        " " *
        Segment(text, style) *
        " ",
    )

    post = Segment(box.top.mid^(length(initial_line) - pre.measure.w - 1), style)

    segments = [Segment(pre * (post), style)]
    return hLine(segments, Measure(segments), width)
end

"""
    hLine(; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Construct an `hLine` as wide as the `stdout`
"""
function hLine(; style::Union{String,Nothing} = nothing, box::Symbol = :ROUNDED)
    return hLine(console_width(); style = style, box = box)
end

"""
    hLine(text::AbstractString; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Construct an `hLine` as wide as the `stdout` with centered text.
"""
function hLine(
    text::AbstractString; style::Union{String,Nothing} = nothing, box::Symbol = :ROUNDED
)
    return hLine(console_width(), text; style = style, box = box)
end
end
