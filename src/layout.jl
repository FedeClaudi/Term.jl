module layout

import Parameters: @with_kw

import Term: int, get_lr_widths, textlen, cint, rtrim_str, ltrim_str
import ..renderables: RenderablesUnion, Renderable, AbstractRenderable, RenderableText
import ..style: apply_style
import ..measure: Measure
import ..segment: Segment
using ..box
import ..box: get_lrow, get_rrow
import ..console: console_width, console_height

export Padding, vstack, hstack, pad, pad!
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
    lw = textlen(text)
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
    pad(text::AbstractString, left::Int=0, right::Int=0)::String

Pad a string by a fixed ammount to the left and to the right.
"""
function pad(text::AbstractString, left::Int=0, right::Int=0)::String
    return " "^left * text * " "^right
end

"""
    pad(segments::Vector{Segment}, left::Int=0, right::Int=0)::Vector{Segment}

Pad a renderable's segments to the left and the right.
"""
function pad(segments::Vector{Segment}, left::Int=0, right::Int=0)::Vector{Segment}
    return map(
        (s)->Segment(" "^left * s.text * " "^right),
        segments
    )
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
    ren.measure = Measure(ren.segments)
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
function leftalign(renderables::RenderablesUnion... )
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)
    renderables = map(r->pad(r, 0, width - r.measure.w), renderables)
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
function leftalign!(renderables::RenderablesUnion... )
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
function center(renderables::RenderablesUnion... )
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)
    renderables = map(r->pad(r;  width=width), renderables)
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
function center!(renderables::RenderablesUnion... )
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)
    for ren in renderables
        pad!(ren; width=width)
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
function rightalign(renderables::RenderablesUnion... )
    length(renderables) < 2 && return renderables
    renderables = Renderable.(renderables)
    width = max(map(r -> r.measure.w, renderables)...)
    renderables = map(r->pad(r, width - r.measure.w, 0), renderables)
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
function rightalign!(renderables::RenderablesUnion... )
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

vstack(s1::String, s2::String) = s1 * "\n" * s2

""" 
    vstack(renderables...)

Vertically stack a variable number of renderables to give a new renderable
"""
function vstack(renderables...)
    renderables = leftalign(renderables...)

    segments::Vector{Segment} = vcat(getfield.(renderables, :segments)...)
    measure = Measure(segments)

    return Renderable(segments, measure)
end

vstack(renderables::Union{Vector, Tuple}) = vstack(renderables...)

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

Horizonatlly stack a variable number of renderables.
"""
function hstack(renderables...)
    renderable = Renderable()

    for ren in renderables
        renderable = hstack(renderable, ren)
    end
    return renderable
end

hstack(renderables::Union{Vector, Tuple}) = hstack(renderables...)

# --------------------------------- operators -------------------------------- #

"""
    Operators for more coincise layout of renderables
"""

Base.:/(r1::RenderablesUnion, r2::RenderablesUnion) = vstack(r1, r2)
Base.:/(rr::Tuple{RenderablesUnion, RenderablesUnion}) = vstack(rr...)


Base.:*(r1::AbstractRenderable, r2::AbstractRenderable) = hstack(r1, r2)
Base.:*(r1::AbstractString, r2::AbstractRenderable) = hstack(r1, r2)
Base.:*(r1::AbstractRenderable, r2::AbstractString) = hstack(r1, r2)


# --------------------------- convenience functions -------------------------- #

"""
    lvstack(renderables::RenderablesUnion...)

Left align renderables and then vertically stack.
"""
function lvstack(renderables::RenderablesUnion...)::Renderable
    renderables = leftalign(renderables...)
    return vstack(renderables...)
end

"""
    lvstack(renderables::RenderablesUnion...)

Center align renderables and then vertically stack.
"""
function cvstack(renderables::RenderablesUnion...)::Renderable
    renderables = center(renderables...)
    return vstack(renderables...)
end

"""
    lvstack(renderables::RenderablesUnion...)

Right align renderables and then vertically stack.
"""
function rvstack(renderables::RenderablesUnion...)::Renderable
    renderables = rightalign(renderables...)
    return vstack(renderables...)
end

rvstack(renderables::Union{Tuple, Vector}) = rvstack(renderables...)
cvstack(renderables::Union{Tuple, Vector}) = cvstack(renderables...)
lvstack(renderables::Union{Tuple, Vector}) = lvstack(renderables...)



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

Spacer(width::Number, height::Number; char::Char = ' ') = Spacer(int(width), int(height); char=char)

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
    height::Int; style::String = "default", box::Symbol = :ROUNDED
)   
    line = apply_style("{"*style*"}" * eval(box).head.left * "{/"*style*"}\e[0m")
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
function hLine(
    width::Int; style::String = "default", box::Symbol = :ROUNDED
)
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

    line =  get_lrow(box, lw-tl, :top; with_left=false) *
            " " * text * " " * 
            "{$style}" * get_rrow(box, rw-tr, :top; with_right=false)

    return hLine([Segment(line, style)], Measure(width, 1))
end

"""
    hLine(; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Construct an `hLine` as wide as the `stdout`.
"""
function hLine(; style::String="default", box::Symbol = :ROUNDED)
    return hLine(console_width(stdout); style = style, box = box)
end

"""
    hLine(text::AbstractString; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

Construct an `hLine` as wide as the `stdout` with centered text.
"""
function hLine(
    text::AbstractString; style::String="default", box::Symbol = :ROUNDED
)
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

function PlaceHolder(w::Int, h::Int)
    # create lines of renderable
    b1 = "╲ "^(w÷2)
    b2 = " ╲"^(w÷2)
    lines::Vector{Segment} = map(
        i -> Segment(i%2 == 0 ? b1 : b2, "dim"), 1:h
    )

    # insert renderable size at center
    txt = "($w × $h)"
    txt = length(txt) % 2 == 0 ? " " * txt : txt
    l = textwidth(txt)

    if l < (w/2)
        _w = cint(w / 2)
        _l = cint(l / 2)
        

        original = lines[cint(h/2)].text
        lines[cint(h/2)] = Segment(
            ltrim_str(original, _w-_l+3) * "{default bold white}" * txt * "{/default bold white}" * rtrim_str(original, _w+_l+3),
        )
    end

    return PlaceHolder(lines, Measure(lines))
end

PlaceHolder(ren::AbstractRenderable) = PlaceHolder(ren.measure.w, ren.measure.h)

# ---------------------------------------------------------------------------- #
#                                     GRID                                     #
# ---------------------------------------------------------------------------- #

"""
    calc_nrows_ncols(n, aspect=(16, 9))

Computes the number of rows and columns to fit a given number `n` of subplots in a figure with aspect `aspect`.
Adapted from: stackoverflow.com/a/43366784
"""
function calc_nrows_ncols(n, aspect=(16, 9))
    w, h = aspect
    factor = √(n / (w * h * 1.0))
    cols = floor(Int, w * factor)
    rows = floor(Int, h * factor)
    rowFirst = w < h
    while rows * cols < n
        if rowFirst
            rows += 1
        else
            cols += 1
        end
        rowFirst = !rowFirst
    end
    return rows, cols
end
"""
    grid(rens::AbstractVector{<:AbstractRenderable}, layout::Union{Nothing,Tuple} = nothing, placeholder = nothing)

Construct a square grid from a `AbsractVector` of `AbstractRenderable`.
"""
function grid(
    rens::AbstractVector{<:AbstractRenderable};
    layout::Union{Nothing,Tuple} = nothing, 
    placeholder = nothing,
    aspect = (16, 9),
)
    num = length(rens)
    m, n = layout === nothing ? calc_nrows_ncols(num, aspect) : layout
    if m === nothing
        m, r = divrem(num, n)
        r == 0 || (m += 1)
    elseif n === nothing
        n, r = divrem(num, m)
        r == 0 || (n += 1)
    end
    fill_in = placeholder === nothing ? PlaceHolder(first(rens)) : placeholder
    return grid(reshape(append!(copy(rens), [fill_in for _ in 1:(m * n - num)]), m, n))
end

"""
    grid(rens::AbstractMatrix{<:AbstractRenderable})

Construct a grid from a `AbstractMatrix` of `AbstractRenderable`.
"""
function grid(rens::AbstractMatrix{<:AbstractRenderable})
    rows = collect(foldl(*, col[2:end], init = first(col)) for col in eachrow(rens))
    return foldl(/, rows[2:end], init = first(rows))
end

end
