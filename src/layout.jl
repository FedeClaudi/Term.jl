module Layout

import Parameters: @with_kw

import Term: int, get_lr_widths, textlen, cint, fint, rtrim_str, ltrim_str, calc_nrows_ncols
import ..Renderables: RenderablesUnion, Renderable, AbstractRenderable, RenderableText
import ..Console: console_width, console_height
import ..Boxes: get_lrow, get_rrow
import ..Style: apply_style
import ..Measures: Measure, height, width
import ..Segments: Segment
using ..Boxes

export Padding, vstack, hstack, pad, pad!, vertical_pad, vertical_pad!
export Spacer, vLine, hLine
export leftalign!, center!, rightalign!
export leftalign, center, rightalign
export lvstack, cvstack, rvstack

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
function pad(text, target_width::Int, method::Symbol)::String
    # get total padding size
    lw = width(text)
    lw >= target_width && return text

    npads = target_width - lw
    if method == :left
        return text * " "^npads
    elseif method == :right
        return " "^npads * text
    else
        nl, nr = get_lr_widths(npads)
        return " "^nl * text * " "^nr
    end
end

"""
    pad(text::AbstractString, left::Int=0, right::Int=0)

Pad a string by a fixed ammount to the left and to the right.
"""
pad(text::AbstractString, left::Int = 0, right::Int = 0) = " "^left * text * " "^right

"""
    pad(segments::AbstractVector{Segment}, left::Int=0, right::Int=0)

Pad a renderable's segments to the left and the right.
"""
function pad(segments::AbstractVector{Segment}, left::Int = 0, right::Int = 0)
    return map((s) -> Segment(pad(s.text, left, right)), segments)
end

"""
    pad(ren::AbstractRenderable, left::Int, right::Int)

Pad a renderable.
"""
function pad(ren::AbstractRenderable, left::Int, right::Int)
    segments = pad(ren.segments, left, right)
    measure = Measure(segments)
    return Renderable(segments, measure)
end

"""
    pad(ren::AbstractRenderable; width::Int)

Pad a renderable to achieve a target width.
"""
function pad(ren::AbstractRenderable; width::Int)
    npads = width - ren.measure.w
    nl, nr = get_lr_widths(npads)
    return pad(ren, nl, nr)
end

"""
    pad!(ren::AbstractRenderable, left::Int, right::Int)

In place version for padding a renderable.
"""
function pad!(ren::AbstractRenderable, left::Int, right::Int)
    ren.segments = pad(ren.segments, left, right)
    return ren.measure = Measure(ren.segments)
end

"""
    pad!(ren::AbstractRenderable; width::Int)

In place version for padding a renderable to achieve a given width.
"""
function pad!(ren::AbstractRenderable; width::Int)
    npads = width - ren.measure.w
    nl, nr = get_lr_widths(npads)
    return pad!(ren, nl, nr)
end

# ------------------------------- vertical pad ------------------------------- #

"""
vertical_pad(text, target_height::Int, method::Symbol)::String

Vertically pad a string to height: `target_height` by adding empty strings above/below " ".
Where the spaces are added depends on the justification `method` ∈ (:top, :center, :bottom).
"""
function vertical_pad(text::AbstractString, target_height::Int, method::Symbol)::String
    # get total padding size
    h = height(text)
    h >= target_height && return text

    space = " "^(width(text))
    npads = target_height - h
    if method == :bottom
        return vertical_pad(text, npads, 0)
    elseif method == :top
        return vertical_pad(text, 0, npads)
    else
        above, below = get_lr_widths(npads)
        return vertical_pad(text, above, below)
    end
end

"""
    vertical_pad(text::AbstractString, above::Int = 0, below::Int = 0)

Vertical pad a string by a fixed ammount to above and below.
"""
function vertical_pad(text::AbstractString, above::Int = 0, below::Int = 0)
    space = " "^(width(text))
    return string(vstack(repeat([space], above)..., text, repeat([space], below)...))
end

"""
    vertical_pad(segments::AbstractVector{Segment}, above::Int = 0, below::Int = 0)

Pad a renderable's segments to the above and the below.
"""
function vertical_pad(segments::AbstractVector{Segment}, above::Int = 0, below::Int = 0)
    space = " "^(segments[1].measure.w)
    above::Vector{Segment} = repeat([Segment(space)], above)
    below::Vector{Segment} = repeat([Segment(space)], below)
    return [above..., segments..., below...]
end

"""
    vertical_pad(ren::AbstractRenderable, above::Int, below::Int)

Pad a renderable, vertically.
"""
function vertical_pad(ren::AbstractRenderable, above::Int, below::Int)
    segments = vertical_pad(ren.segments, above, below)
    measure = Measure(segments)
    return Renderable(segments, measure)
end

"""
vertical_pad(ren::AbstractRenderable; height::Int)

Vertical pad a renderable to achieve a target height.
"""
function vertical_pad(ren::AbstractRenderable; height::Int)
    npads = height - ren.measure.h
    nl, nr = get_lr_widths(npads)
    return vertical_pad(ren, nl, nr)
end

"""
    verti0cal_pad!(ren::AbstractRenderable, above::Int, below::Int)

In place version for vertically padding a renderable.
"""
function vertical_pad!(ren::AbstractRenderable, above::Int, below::Int)
    ren.segments = vertical_pad(ren.segments, above, below)
    return ren.measure = Measure(ren.segments)
end

"""
    pad!(ren::AbstractRenderable; width::Int)

In place version for padding a renderable to achieve a given width.
"""
function vertical_pad!(ren::AbstractRenderable; height::Int)
    npads = height - ren.measure.h
    nl, nr = get_lr_widths(npads)
    return vertical_pad!(ren, nl, nr)
end

# ---------------------------------------------------------------------------- #
#                                    JUSTIFY                                   #
# ---------------------------------------------------------------------------- #
"""
    leftalign(renderables::RenderablesUnion...)

Pad two (or more) renderables so that they have the same width and they
are left-aligned.

NOTE: the renderables returned  have different type and potentially different size
    from the inputs

# Examples
```julia
p1 = Panel(; width=25)
p2 = Panel(; width=50)
p1, p2 = leftalign(p1, p2)
print(p1/p2)


╭───────────────────────╮                         
╰───────────────────────╯                         
╭────────────────────────────────────────────────╮
╰────────────────────────────────────────────────╯
```
"""
function leftalign(renderables::RenderablesUnion...)
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)
    renderables = map(r -> pad(r, 0, width - r.measure.w), renderables)
    return renderables
end

"""
    leftalign!(renderables::RenderablesUnion...)

In place version of leftalign. 

# Examples
```julia
p1 = Panel(; width=25)
p2 = Panel(; width=50)
leftalign!(p1, p2)
print(p1/p2)


╭───────────────────────╮                         
╰───────────────────────╯                         
╭────────────────────────────────────────────────╮
╰────────────────────────────────────────────────╯
"""
function leftalign!(renderables::RenderablesUnion...)
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)
    for ren in renderables
        pad!(ren, 0, width - ren.measure.w)
    end
end

"""
    center(renderables::RenderablesUnion... )

Pad two (or more) renderables so that they have the same width and they
are centered.

NOTE: the renderables returned  have different type and potentially different size
    from the inputs

# Examples
```julia
p1 = Panel(; width=25)
p2 = Panel(; width=50)
p1, p2 = center(p1, p2)
print(p1/p2)

             ╭───────────────────────╮             
             ╰───────────────────────╯             
╭────────────────────────────────────────────────╮
╰────────────────────────────────────────────────╯
```
"""
function center(renderables::RenderablesUnion...)
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)
    renderables = map(r -> pad(r; width = width), renderables)
    return renderables
end

"""
    center!(renderables::RenderablesUnion... )

In place version of `center`.


# Examples
```julia
p1 = Panel(; width=25)
p2 = Panel(; width=50)
center!(p1, p2)
print(p1/p2)

             ╭───────────────────────╮             
             ╰───────────────────────╯             
╭────────────────────────────────────────────────╮
╰────────────────────────────────────────────────╯
```
"""
function center!(renderables::RenderablesUnion...)
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)
    for ren in renderables
        pad!(ren; width = width)
    end
end

"""
    rightalign(renderables::RenderablesUnion... )

Pad two (or more) renderables so that they have the same width and they
are right aligned.

NOTE: the renderables returned  have different type and potentially different size
    from the inputs

# Examples
```julia
p1 = Panel(; width=25)
p2 = Panel(; width=50)
p1, p2 = rightalign(p1, p2)
print(p1/p2)

                         ╭───────────────────────╮
                         ╰───────────────────────╯
╭────────────────────────────────────────────────╮
╰────────────────────────────────────────────────╯
```
"""
function rightalign(renderables::RenderablesUnion...)
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)
    renderables = map(r -> pad(r, width - r.measure.w, 0), renderables)
    return renderables
end

"""
    rightalign!(renderables::RenderablesUnion... )

In place version of `rightalign`.
# Examples
```julia
p1 = Panel(; width=25)
p2 = Panel(; width=50)
rightalign!(p1, p2)
print(p1/p2)

                         ╭───────────────────────╮
                         ╰───────────────────────╯
╭────────────────────────────────────────────────╮
╰────────────────────────────────────────────────╯
```
"""
function rightalign!(renderables::RenderablesUnion...)
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)

    for ren in renderables
        pad!(ren, width - ren.measure.w, 0)
    end
end

# ---------------------------------------------------------------------------- #
#                                   STACKING                                   #
# ---------------------------------------------------------------------------- #

vstack(s1::String, s2::String; pad::Int = 0) = s1 * "\n"^(pad + 1) * s2

""" 
    vstack(renderables...)

Vertically stack a variable number of renderables to give a new renderable
"""
function vstack(renderables...; pad::Int = 0)
    renderables = leftalign(renderables...)

    segments::Vector{Segment} = []
    if pad > 0
        renderables = foldl((a, b) -> a / ("\n"^pad) / b, renderables)
        segments = renderables.segments
    else
        segments = vcat(getfield.(renderables, :segments)...)
    end
    measure = Measure(segments)
    return Renderable(segments, measure)
end

vstack(renderables::Union{Vector,Tuple}; kwargs...) = vstack(renderables...; kwargs...)

"""
    hstack(r1::RenderablesUnion, r2::RenderablesUnion)

Horizontally stack two renderables to give a new renderable.
"""
function hstack(r1::RenderablesUnion, r2::RenderablesUnion; pad::Int = 0)
    r1 = r1 isa AbstractRenderable ? r1 : Renderable(r1)
    r2 = r2 isa AbstractRenderable ? r2 : Renderable(r2)

    # get dimensions of final renderable
    h1 = r1.measure.h
    h2 = r2.measure.h
    Δh = abs(h2 - h1)

    # make sure both renderables have the same number of segments
    if h1 > h2
        s1 = r1.segments
        s2 = vcat(r2.segments, [Segment(" "^(r2.measure.w + pad)) for i in 1:(Δh)])
    elseif h1 < h2
        s1 = vcat(r1.segments, [Segment(" "^(r1.measure.w + pad)) for i in 1:(Δh)])
        s2 = r2.segments
    else
        s1, s2, = r1.segments, r2.segments
    end

    # combine segments
    segments = [Segment(s1.text * " "^pad * s2.text) for (s1, s2) in zip(s1, s2)]

    return Renderable(
        segments,
        Measure(r1.measure.w + r2.measure.w, max(r1.measure.h, r2.measure.h)),
    )
end

""" 
    hstack(renderables...)

Horizonatlly stack a variable number of renderables.
"""
function hstack(renderables...; pad::Int = 0)
    renderable = Renderable()

    for (i, ren) in enumerate(renderables)
        _pad = i == 1 ? 0 : pad
        renderable = hstack(renderable, ren; pad = _pad)
    end
    return renderable
end

hstack(renderables::Union{Vector,Tuple}; kwargs...) = hstack(renderables...; kwargs...)

# --------------------------------- operators -------------------------------- #

"""
    Operators for more coincise layout of renderables
"""

Base.:/(r1::RenderablesUnion, r2::RenderablesUnion) = vstack(r1, r2)
Base.:/(rr::Tuple{RenderablesUnion,RenderablesUnion}) = vstack(rr...)

Base.:*(r1::AbstractRenderable, r2::AbstractRenderable) = hstack(r1, r2)
Base.:*(r1::AbstractString, r2::AbstractRenderable) = hstack(r1, r2)
Base.:*(r1::AbstractRenderable, r2::AbstractString) = hstack(r1, r2)

# --------------------------- convenience functions -------------------------- #

"""
    lvstack(renderables::RenderablesUnion...)

Left align renderables and then vertically stack.
"""
function lvstack(renderables::RenderablesUnion...; kwargs...)::Renderable
    renderables = leftalign(renderables...)
    return vstack(renderables...; kwargs...)
end

"""
    lvstack(renderables::RenderablesUnion...)

Center align renderables and then vertically stack.
"""
function cvstack(renderables::RenderablesUnion...; kwargs...)::Renderable
    renderables = center(renderables...)
    return vstack(renderables...; kwargs...)
end

"""
    lvstack(renderables::RenderablesUnion...)

Right align renderables and then vertically stack.
"""
function rvstack(renderables::RenderablesUnion...; kwargs...)::Renderable
    renderables = rightalign(renderables...)
    return vstack(renderables...; kwargs...)
end

rvstack(renderables::Union{Tuple,Vector}; kwargs...) = rvstack(renderables...; kwargs...)
cvstack(renderables::Union{Tuple,Vector}; kwargs...) = cvstack(renderables...; kwargs...)
lvstack(renderables::Union{Tuple,Vector}; kwargs...) = lvstack(renderables...; kwargs...)

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

function Spacer(width::Int, height::Int; char::Char = ' ')
    line = char^width
    seg = Segment(line)
    segments = repeat([seg], height)
    return Spacer(segments, Measure(seg.measure.w, height))
end

function Spacer(width::Number, height::Number; char::Char = ' ')
    return Spacer(int(width), int(height); char = char)
end

# ----------------------------------- vline ---------------------------------- #
"""
    vLine

A multi-line renderable with each line made of a | to create a vertical line.
"""
mutable struct vLine <: AbstractLayoutElement
    segments::Vector{Segment}
    measure::Measure
end

"""
    vLine(height::Number, style::Union{String, Nothing}; box::Symbol=:ROUNDED)

Create a `vLine` given a height and, optionally, style information.
"""
function vLine(
    height::Int;
    style::String = "default",
    box::Symbol = :ROUNDED,
    char::Union{Char,Nothing} = nothing,
)
    char = isnothing(char) ? getfield(Boxes, box).head.left : char
    line = apply_style("{" * style * "}" * char * "{/" * style * "}\e[0m")
    segments = repeat([Segment(line)], height)
    return vLine(segments, Measure(1, height))
end

"""
    vLine(ren::AbstractRenderable; kwargs...)

Construct a vLine with the same height as a renderable.
"""
vLine(ren::AbstractRenderable; kwargs...) = vLine(ren.measure.h; kwargs...)

"""
    vLine(; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Create a `vLine` as tall as the `stdout` console.
"""
function vLine(; style::String = "default", box::Symbol = :ROUNDED)
    return vLine(console_height(stdout); style = style, box = box)
end

# ----------------------------------- hLine ---------------------------------- #

"""
    hLine

A 1-line renderable made of repeated character from a Box.
"""
mutable struct hLine <: AbstractLayoutElement
    segments::Vector{Segment}
    measure::Measure
end

"""
    hLine(width::Number, style::Union{String, Nothing}; box::Symbol=:ROUNDED)

Create a styled `hLine` of given width.
"""
function hLine(width::Int; style::String = "default", box::Symbol = :ROUNDED)
    char = eval(box).row.mid
    segments = [Segment(char^width, style)]
    return hLine(segments, Measure(width, 1))
end

"""
    hLine(width::Number, text::String; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Creates an hLine object with texte centered horizontally.
"""
function hLine(
    width::Number,
    text::String;
    style::String = "default",
    box::Symbol = :ROUNDED,
)
    box = eval(box)
    text = apply_style(text)
    tl, tr = get_lr_widths(textlen(text))
    lw, rw = get_lr_widths(width)

    line =
        get_lrow(box, lw - tl, :top; with_left = false) *
        " " *
        text *
        " " *
        "{$style}" *
        get_rrow(box, rw - tr, :top; with_right = false)

    return hLine([Segment(line, style)], Measure(width, 1))
end

"""
    hLine(; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Construct an `hLine` as wide as the `stdout`.
"""
function hLine(; style::String = "default", box::Symbol = :ROUNDED)
    return hLine(console_width(stdout); style = style, box = box)
end

"""
    hLine(text::AbstractString; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Construct an `hLine` as wide as the `stdout` with centered text.
"""
function hLine(text::AbstractString; style::String = "default", box::Symbol = :ROUNDED)
    return hLine(console_width(stdout), text; style = style, box = box)
end

"""
    hLine(ren::AbstractRenderable; kwargs)

Construct an hLine with same width as a renderable.
"""
hLine(ren::AbstractRenderable; kwargs...) = hLine(ren.measure.w; kwargs...)

# -------------------------------- PlaceHolder ------------------------------- #

"""
    PlaceHolder

A renderable used as a place holder when creating layouts (e.g. with `grid`).

# Examples
```julia

println(PlaceHolder(25, 10))


╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲
╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ 
 ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲
╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ 
 ╲ ╲ ╲ (25 × 10) ╲ ╲ ╲ ╲
╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ 
 ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲
╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ 
 ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲
╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ 
````
"""
mutable struct PlaceHolder <: AbstractLayoutElement
    segments::Vector{Segment}
    measure::Measure
end

function place_holder_line(w, i)
    if w > 1
        if w % 2 == 0
            left, right = w ÷ 2, w ÷ 2
            line = i == 0 ? "╲ "^(left) : " ╲"^(right)
        else
            left = cint(w / 2)
            line = i == 0 ? "╲ "^(left) : " ╲"^(left)
            line = ltrim_str(line, w)
        end

    else
        line = i == 0 ? "╲" : " "
    end
    return line
end

function PlaceHolder(
    w::Int,
    h::Int;
    style::String = "dim",
    text::Union{Nothing,String} = nothing,
)
    # create lines of renderable
    b1 = place_holder_line(w, 0)
    b2 = place_holder_line(w, 1)
    lines::Vector{Segment} = map(i -> Segment(i % 2 != 0 ? b1 : b2, style), 1:h)

    # insert renderable size at center
    text = isnothing(text) ? "($w × $h)" : text
    text = "  " * text * "  "
    text = width(text) % 2 == 0 ? " " * text : text
    l = width(text)

    if l < (w / 2) && w > 13
        f = w < 30 ? 2.5 : 3
        _w = cint(ncodeunits(lines[1].text) / f)
        _l = cint(l / 2)

        original = lines[cint(h / 2)].text
        lines[cint(h / 2)] = Segment(
            ltrim_str(original, _w - _l) *
            "{default bold white}" *
            text *
            "{/default bold white}" *
            rtrim_str(original, _w + _l),
        )
    end

    return PlaceHolder(lines, Measure(lines))
end

PlaceHolder(ren::AbstractRenderable) = PlaceHolder(ren.measure.w, ren.measure.h)

end
