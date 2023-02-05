module Layout

import Parameters: @with_kw

import Term:
    rint,
    get_lr_widths,
    textlen,
    cint,
    fint,
    rtrim_str,
    ltrim_str,
    do_by_line,
    get_bg_color,
    TERM_THEME,
    string_type

import Term: justify as justify_text
import ..Renderables: RenderablesUnion, Renderable, AbstractRenderable, RenderableText
import ..Consoles: console_width, console_height
import ..Measures: Measure, height, width
import ..Boxes: get_lrow, get_rrow
import ..Style: apply_style
import ..Segments: Segment, get_string_types
using ..Boxes

export Padding, vstack, hstack, pad, pad!, vertical_pad, vertical_pad!
export Spacer, vLine, hLine, PlaceHolder
export leftalign!, center!, rightalign!
export leftalign, center, rightalign
export lvstack, cvstack, rvstack
export Placeholder

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

Padding(padding::Tuple) = Padding(padding...)

"""
    pad(text::AbstractString, target_width::Int, method::Symbol)::String

Pad a string to width: `target_width` by adding empty spaces strings " ".
Where the spaces are added depends on the justification `method` ∈ (`:left`, `:center`, `:right`, `:justify`).

#### Examples

``` julia
julia> pad("ciao", 10, :left)
"ciao      "

julia> pad("ciao", 10, :center)
"   ciao   "

julia> pad("ciao", 10, :right)
"      ciao"
```
"""
function pad(text::AbstractString, target_width::Int, method::Symbol; bg = nothing)
    bg = get_bg_color(bg)
    occursin('\n', text) &&
        return do_by_line(ln -> pad(ln, target_width, method; bg = bg), text)

    # get total padding size
    lw = width(text)
    lw ≥ target_width && return text
    return pad(text, target_width, method, lw; bg = bg)
end

"""
    function pad(text::AbstractString, target_width::Int, method::Symbol, lw::Int; bg = nothing)::String

complete string padding but knowing line width of the string.
Useful in cases the line width needs to be enforced instead of obtained through `width(text)`, e.g.
when paddnig a `Link`'s text.
"""
function pad(text::AbstractString, target_width::Int, method::Symbol, lw::Int; bg = nothing)
    stype = string_type(text)
    npads = target_width - lw
    # println("TEXT ", text, " NPADS ", npads, " METHOD ", method, " lw ", lw)
    if method ≡ :left
        p = isnothing(bg) ? ' '^npads : "{$bg}" * ' '^npads * "{/$bg}"
        return text * p |> stype
    elseif method ≡ :right
        p = isnothing(bg) ? ' '^npads : "{$bg}" * ' '^npads * "{/$bg}"
        return p * text |> stype
    else
        nl, nr = get_lr_widths(npads)
        l = isnothing(bg) ? ' '^nl : "{$bg}" * ' '^nl * "{/$bg}"
        r = isnothing(bg) ? ' '^nr : "{$bg}" * ' '^nr * "{/$bg}"
        t = l * text * r
        return t |> stype
    end
end

"""
---
    pad(text::AbstractString, left::Int = 0, right::Int = 0)

Pad a string by a fixed ammount to the left and to the right.
"""
function pad(text::AbstractString, left::Int = 0, right::Int = 0; bg = nothing)
    stype = string_type(text)
    if isnothing(bg)
        (' '^max(0, left) * text * ' '^max(0, right)) |> stype
    else
        l = "{$bg}" * ' '^max(0, left) * "{/$bg}"
        r = "{$bg}" * ' '^max(0, right) * "{/$bg}"
        (l * text * r) |> stype
    end
end

"""
    pad(s::Segment, left::Int = 0, right::Int = 0; kwargs...)

Pad a segment.
"""
pad(s::Segment, left::Int = 0, right::Int = 0; kwargs...) = Segment(
    pad(s.text, left, right; kwargs...),
    Measure(s.measure.h, s.measure.w + left + right),
)

function pad(s::Segment, width::Int, method::Symbol; kwargs...)
    return if width <= s.measure.w
        s
    else
        Segment(
            pad(s.text, width, method, s.measure.w; kwargs...),
            Measure(s.measure.h, width),
        )
    end
end

"""
---
    pad(segments::AbstractVector{Segment}, left::Int = 0, right::Int = 0)

Pad a renderable's segments to the left and the right.
"""
pad(segments::AbstractVector{Segment}, left::Int = 0, right::Int = 0; kwargs...) =
    map((s) -> pad(s, left, right; kwargs...), segments)

"""
---
    pad(ren::AbstractRenderable, left::Int, right::Int)

Pad an `AbstractRenderable` by padding each of its segments.
"""
function pad(ren::AbstractRenderable, left::Int, right::Int; kwargs...)
    segments = pad(ren.segments, left, right; kwargs...)
    return Renderable(segments, Measure(segments))
end

"""
---
    pad(ren::AbstractRenderable; width::Int)


Pad a renderable to achieve a target width.

!!! note
    The padding is added to the left and to the right as needed to achieve the target width.
    The resulting renderable object will be **center** in the target space.

#### Example
```
julia> pad(RenderableText("ciao"); width=10)
    ciao   
```
"""
function pad(ren::AbstractRenderable; width::Int, method = :center)
    ren.measure.w >= width && return ren

    if method == :center
        nl, nr = get_lr_widths(width - ren.measure.w)
    elseif method == :right
        nl, nr = 0, width - ren.measure.w
    else
        nl, nr = width - ren.measure.w, 0
    end
    return pad(ren, nl, nr)
end

"""
    pad!(ren::AbstractRenderable, left::Int, right::Int)

In place version for padding a renderable.
"""
function pad!(ren::AbstractRenderable, left::Int, right::Int)
    ren.segments = pad(ren.segments, left, right)
    ren.measure = Measure(ren.segments)
    nothing
end

"""
    pad!(ren::AbstractRenderable; width::Int)

In place version for padding a renderable to achieve a given width.
"""
function pad!(ren::AbstractRenderable; width::Int)
    ren.measure.w >= width && return ren
    nl, nr = get_lr_widths(width - ren.measure.w)
    return pad!(ren, nl, nr)
end

# ------------------------------- vertical pad ------------------------------- #

"""
vertical_pad(text, target_height::Int, method::Symbol)::String

Vertically pad a string to height: `target_height` by adding empty strings above/below " ".
Where the spaces are added depends on the justification `method` ∈ (:top, :center, :bottom).
"""
function vertical_pad(text::AbstractString, target_height::Int, method::Symbol)
    # get total padding size
    h = height(text)
    h ≥ target_height && return text

    npads = target_height - h
    return if method ≡ :bottom
        vertical_pad(text, npads, 0)
    elseif method ≡ :top
        vertical_pad(text, 0, npads)
    else
        above, below = get_lr_widths(npads)
        vertical_pad(text, above, below)
    end
end

# vertical_pad(text::AbstractString; height::Int, method::Symbol=:center) = vertical_pad(text, height, method)

"""
    vertical_pad(text::AbstractString, above::Int = 0, below::Int = 0)

Vertical pad a string by a fixed ammount to above and below.
"""
function vertical_pad(text::AbstractString, above::Int = 0, below::Int = 0)
    stype = string_type(text)
    space = ' '^(width(text))
    return stype(vstack(fill(space, above)..., text, fill(space, below)...))
end

"""
    vertical_pad(segments::AbstractVector{Segment}, above::Int = 0, below::Int = 0)

Pad a renderable's segments to the above and the below.
"""
function vertical_pad(segments::AbstractVector{Segment}, above::Int = 0, below::Int = 0)
    space = ' '^(segments[1].measure.w)
    above::Vector{Segment} = fill(Segment(space), above)
    below::Vector{Segment} = fill(Segment(space), below)
    return [above..., segments..., below...]
end

"""
    vertical_pad(ren::AbstractRenderable, above::Int, below::Int)

Pad a renderable, vertically.
"""
function vertical_pad(ren::AbstractRenderable, above::Int, below::Int)
    segments = vertical_pad(ren.segments, above, below)
    return Renderable(segments, Measure(segments))
end

"""
vertical_pad(ren::AbstractRenderable; height::Int)

Vertical pad a renderable to achieve a target height.
"""
function vertical_pad(ren::AbstractRenderable; height::Int, method = :center)
    ren.measure.h >= height && return ren
    if method == :center
        n_above, n_below = get_lr_widths(height - ren.measure.h)
    elseif method == :bottom
        n_above, n_below = height - ren.measure.h, 0
    elseif method == :top
        n_above, n_below = 0, height - ren.measure.h
    end
    return vertical_pad(ren, n_above, n_below)
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
    nl, nr = get_lr_widths(height - ren.measure.h)
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
    width = maximum(map(r -> r.measure.w, renderables))
    return map(r -> pad(r, 0, width - r.measure.w), renderables)
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
    width = maximum(map(r -> r.measure.w, renderables))
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
    width = maximum(map(r -> r.measure.w, renderables))
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
    width = maximum(map(r -> r.measure.w, renderables))
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
    width = maximum(map(r -> r.measure.w, renderables))
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
    width = maximum(map(r -> r.measure.w, renderables))

    for ren in renderables
        pad!(ren, width - ren.measure.w, 0)
    end
end

# ---------------------------------------------------------------------------- #
#                                   STACKING                                   #
# ---------------------------------------------------------------------------- #

vstack(s1::String, s2::String; pad::Int = 0) = s1 * '\n'^(pad + 1) * s2

""" 
    vstack(renderables...)

Vertically stack a variable number of renderables to give a new renderable
"""
function vstack(renderables::RenderablesUnion...; pad::Int = 0)
    renderables = leftalign(renderables...)
    segments = if pad > 0
        foldl((a, b) -> a / ('\n'^pad) / b, renderables).segments
    else
        vcat(
            map(
                r -> r isa AbstractRenderable ? getfield(r, :segments) : Segment(r),
                renderables,
            )...,
        )
    end
    return Renderable(segments, Measure(segments))
end

vstack(renderables::Union{AbstractVector,Tuple}; kwargs...) =
    vstack(renderables...; kwargs...)

"""
    hstack(r1::RenderablesUnion, r2::RenderablesUnion   )

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
        s2 = vcat(r2.segments, fill(Segment(' '^(r2.measure.w)), Δh))
    elseif h1 < h2
        s1 = vcat(r1.segments, fill(Segment(' '^(r1.measure.w)), Δh))
        s2 = r2.segments
    else
        s1, s2, = r1.segments, r2.segments
    end

    # combine segments
    stype = get_string_types(s1, s2)
    segments = [
        Segment(
            stype(ss1.text * ' '^pad * ss2.text),
            Measure(1, ss1.measure.w + pad + ss2.measure.w),
        ) for (ss1, ss2) in zip(s1, s2)
    ]
    return Renderable(segments, Measure(segments))
end

""" 
    hstack(renderables...)

Horizonatlly stack a variable number of renderables.
"""
function hstack(renderables...; pad::Int = 0)
    renderable = Renderable()
    for (i, ren) in enumerate(renderables)
        renderable = hstack(renderable, ren; pad = i == 1 ? 0 : pad)
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

# --------------------------- convenience functions -------------------------- #

"""
    lvstack(renderables::RenderablesUnion...)

Left align renderables and then vertically stack.
"""
lvstack(renderables::RenderablesUnion...; kwargs...)::Renderable =
    vstack(leftalign(renderables...)...; kwargs...)

"""
    lvstack(renderables::RenderablesUnion...)

Center align renderables and then vertically stack.
"""
cvstack(renderables::RenderablesUnion...; kwargs...)::Renderable =
    vstack(center(renderables...)...; kwargs...)

"""
    lvstack(renderables::RenderablesUnion...)

Right align renderables and then vertically stack.
"""
rvstack(renderables::RenderablesUnion...; kwargs...)::Renderable =
    vstack(rightalign(renderables...)...; kwargs...)

rvstack(renderables::Union{Tuple,AbstractVector}; kwargs...) =
    rvstack(renderables...; kwargs...)
cvstack(renderables::Union{Tuple,AbstractVector}; kwargs...) =
    cvstack(renderables...; kwargs...)
lvstack(renderables::Union{Tuple,AbstractVector}; kwargs...) =
    lvstack(renderables...; kwargs...)

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

function Spacer(height::Int, width::Int; char::Char = ' ')
    seg = Segment(char^width)
    return Spacer(fill(seg, height), Measure(height, seg.measure.w))
end

Spacer(height::Number, width::Number; char::Char = ' ') =
    Spacer(rint(height), rint(width); char = char)

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
    vLine(
        height::Int;
        style::String = TERM_THEME[].line,
        box::Symbol = TERM_THEME[].box,
        char::Union{Char,Nothing} = nothing,
    )

Create a `vLine` given a height and, optionally, style information.
"""
function vLine(
    height::Int;
    style::String = TERM_THEME[].line,
    box::Symbol = TERM_THEME[].box,
    char::Union{Char,Nothing} = nothing,
)
    char = isnothing(char) ? BOXES[box].head.left : char
    line = apply_style("{" * style * "}" * char * "{/" * style * "}\e[0m")
    return vLine(fill(Segment(line), height), Measure(height, 1))
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
vLine(; style::String = TERM_THEME[].line, box::Symbol = TERM_THEME[].box) =
    vLine(console_height(stdout); style = style, box = box)

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
    hLine(width::Number, style::Union{String, Nothing}; box::Symbol=TERM_THEME[].box)

Create a styled `hLine` of given width.
"""
hLine(width::Int; style::String = TERM_THEME[].line, box::Symbol = TERM_THEME[].box) =
    hLine([Segment(BOXES[box].row.mid^width * "\e[0m", style)], Measure(1, width))

"""
    hLine(width::Number, text::String; style::Union{String, Nothing}=nothing, box::Symbol=TERM_THEME[].box)

Creates an hLine object with texte centered horizontally.
"""
function hLine(
    width::Number,
    text::String;
    style::String = TERM_THEME[].line,
    box::Symbol = TERM_THEME[].box,
    pad_txt::Bool = true,
)
    box = BOXES[box]
    text = apply_style(text) * "{$style}"
    tl, tr = get_lr_widths(textlen(text))
    lw, rw = get_lr_widths(width)
    _pad = pad_txt ? " " : get_lrow(box, 1, :top; with_left = false)

    line =
        "{$style}" *
        get_lrow(box, lw - tl, :top; with_left = false) *
        _pad *
        text *
        _pad *
        "{$style}" *
        get_rrow(box, rw - tr, :top; with_right = false) *
        "{/$style}{/$style}" *
        "\e[0m"

    return hLine([Segment(line)], Measure(1, width))
end

"""
    hLine(; style::Union{String, Nothing}=nothing, box::Symbol=TERM_THEME[].box)

Construct an `hLine` as wide as the `stdout`.
"""
hLine(; style::String = TERM_THEME[].line, box::Symbol = TERM_THEME[].box) =
    hLine(console_width(stdout); style = style, box = box)

"""
    hLine(text::AbstractString; style::Union{String, Nothing}=nothing, box::Symbol=TERM_THEME[].box)

Construct an `hLine` as wide as the `stdout` with centered text.
"""
hLine(
    text::AbstractString;
    style::String = TERM_THEME[].line,
    box::Symbol = TERM_THEME[].box,
) = hLine(console_width(stdout), text; style = style, box = box)

"""
    hLine(ren::AbstractRenderable; kwargs)

Construct an hLine with same width as a renderable.
"""
hLine(ren::AbstractRenderable; kwargs...) = hLine(ren.measure.w; kwargs...)

# -------------------------------- PlaceHolder ------------------------------- #

"""
    mutable struct PlaceHolder <: AbstractLayoutElement
        segments::Vector{Segment}
        measure::Measure
    end
A `renderable` used as a place holder when creating layouts (e.g. with `grid`).

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
```
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
        line = i == 0 ? '╲' : ' '
    end
    return line
end

"""
    PlaceHolder(
        h::In,
        w::Int;
        style::String = "dim",
        text::Union{Nothing,String} = nothing,
    )

Create a `PlaceHolder` with additional style information.
"""
function PlaceHolder(
    h::Int,
    w::Int;
    style::String = "dim",
    text::Union{Nothing,String} = nothing,
)
    # create lines of renderable
    b1 = place_holder_line(w, 0)
    b2 = place_holder_line(w, 1)
    lines::Vector{Segment} = map(i -> Segment(i % 2 != 0 ? b1 : b2, style), 1:h)

    # insert renderable size at center
    text = something(text, "($h × $w)")
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
            "{/default bold white}{$style}" *
            rtrim_str(original, _w + _l),
        )
    end

    return PlaceHolder(lines, Measure(lines))
end

PlaceHolder(ren::AbstractRenderable; kwargs...) =
    PlaceHolder(ren.measure.h, ren.measure.w; kwargs...)

end
