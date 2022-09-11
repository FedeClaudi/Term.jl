module Dendograms

import Term: fint, rint, cint, str_trunc, loop_firstlast, highlight, textlen, TERM_THEME

import ..Renderables: AbstractRenderable
import ..Boxes: get_rrow, get_lrow, get_row, BOXES
import ..Style: apply_style
import ..Segments: Segment
import ..Measures: Measure
import ..Layout: pad

export Dendogram, link

CELLWIDTH = 10
SPACING = 1

# ---------------------------------------------------------------------------- #
#                                     LEAF                                     #
# ---------------------------------------------------------------------------- #

"""
    Leaf <: AbstractRenderable

The terminal element of a `Dendogram`.
"""
struct Leaf <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
    text::String
    midpoint::Int
end

"""
    Leaf(leaf)

Construct a `Leaf` out of any object.
"""
function Leaf(leaf)
    # get a string representation of the appropriate length
    leaf = string(leaf)
    leaf = if textlen(leaf) > CELLWIDTH
        str_trunc(leaf, CELLWIDTH)
    else
        pad(leaf, CELLWIDTH + 1, :center)
    end

    # create renderable Leaf
    midpoint = fint(textlen(leaf) / 2)
    seg = Segment(" " * leaf * " ", TERM_THEME[].dendo_leaves)
    return Leaf([seg], Measure(seg), leaf, midpoint)
end

function Base.string(leaf::Leaf, isfirst::Bool, islast::Bool, spacing::Int)
    l = isfirst ? "" : " "^spacing
    r = islast ? "" : " "^spacing
    return l * leaf.text * r
end

# ---------------------------------------------------------------------------- #
#                                   DENDOGRAM                                  #
# ---------------------------------------------------------------------------- #

"""
    Dendogram <: AbstractRenderable

A Dendogram tree renderable.
"""
struct Dendogram <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
    midpoint::Int  # width of 'center'
end

"""
    Dendogram(head, args::Vector; first_arg=nothing, pretitle=nothing)

Construct a single `Dendogram`.

Construct a dendogram with one head node (`head`) and any number of leaves.

`first_arg` is used to create dendograms for `Expr` objects and gives special
status to an expression's first argument which gets printed with the head.
`pretitle` is used to create dendograms for `Expr`, pretitle is insrted as 
three `Segment`s (a string and an upward arrow) before the head of the dendogram.
"""
function Dendogram(head, args::Vector; first_arg = nothing, pretitle = nothing)
    # get leaves
    leaves = Leaf.(args)
    leaves_line =
        join(map(nl -> string(nl[3], nl[1], nl[2], SPACING), loop_firstlast(leaves)))
    width = textlen(leaves_line)

    # get tree structure line
    if length(leaves) > 1
        widths = fill(CELLWIDTH + 1 + SPACING, length(leaves) - 1)
        line = pad(
            replace_line_midpoint(get_row(BOXES[:SQUARE], widths, :top))[1],
            width,
            :center,
        )
    else
        widths = [CELLWIDTH]
        line = pad(string(BOXES[:SQUARE].bottom.vertical), CELLWIDTH, :center)
    end

    # get title
    title_style = TERM_THEME[].dendo_title
    pretitle_style = TERM_THEME[].dendo_pretitle
    line_style = TERM_THEME[].dendo_lines

    title = if isnothing(first_arg)
        pad(apply_style("$(head)", title_style), width, :center)
    else
        _title = ": {bold default underline $title_style}$first_arg{/bold default underline $title_style}"
        pad(apply_style("$(head)$_title", title_style * " dim"), width - 4, :center) * " "^4
    end

    # put together
    segments = [
        Segment(title),
        Segment(line, line_style),
        Segment(leaves_line, TERM_THEME[].dendo_leaves),
    ]

    # add 'pretitle' lines (for expressions only)
    if !isnothing(pretitle)
        prepend!(
            segments,
            [
                Segment(
                    " " * pad(str_trunc(pretitle, CELLWIDTH), width - 1, :center),
                    pretitle_style,
                ),
                Segment(" " * pad("⋀", width - 1, :center), "$line_style bold"),
                Segment(
                    " " * pad(string(BOXES[:SQUARE].bottom.vertical), width - 1, :center),
                    "$line_style dim",
                ),
            ],
        )
    end

    return Dendogram(segments, Measure(segments), rint(width / 2))
end

Dendogram(head, args...; kwargs...) = Dendogram(head, collect(args); kwargs...)

"""
    Dendogram(e::Expr; pretitle=nothing)

Create a Dendogram representation for an `Expr`. 
For expressions whose arguments are themselves `Expr` objects, dendograms
are created recursively. In the end all dendograms are linked using `link`
to create a single dendogram object (possibly nested).

`pretitle` is used to create dendograms for `Expr`, pretitle is insrted as 
three `Segment`s (a string and an upward arrow) before the head of the dendogram.
"""
function Dendogram(e::Expr; pretitle = nothing)
    length(e.args) == 1 && return Dendogram(e.head, e.args)

    # if there's no more nested expressions, return a dendogram
    !any(isa.(e.args[2:end], Expr)) && return Dendogram(
        e.head,
        e.args[2:end];
        first_arg = e.args[1],
        pretitle = replace(string(e), ' ' => ""),
    )

    # recursively get leaves, creating dendograms for sub expressions
    leaves = map(
        arg -> if arg isa Expr
            Dendogram(arg; pretitle = replace(string(arg), ' ' => ""))
        else
            Leaf(arg)
        end,
        length(e.args) > 2 ? e.args[2:end] : e.args,
    )

    # make dendogram by linking individual elements
    title = apply_style(
        "$(e.head): {bold underline default $(TERM_THEME[].dendo_title)}$(e.args[1]){/bold underline default $(TERM_THEME[].dendo_title)}",
        TERM_THEME[].dendo_title,
    )
    return link(leaves...; title = title, shifttitle = true, pretitle = pretitle)
end

# ---------------------------------------------------------------------------- #
#                                     LINK                                     #
# ---------------------------------------------------------------------------- #
"""
    link(dendos...; title="", shifttitle=false, pretitle=nothing)::Dendogram

Link a variable number of `Dendogram` and `Leaf` objects in a new `Dendogram`.

Create a `Dendogram` whose leaves are other leaves and dendograms. 
This is done carefully to ensure that all spacings are correct and text
is aligned as much as possible. 

Annoyingly, the code is very similar to that of `Dendogram` but different enough
that it can't be refactored into single functions.
"""
function link(dendos...; title = "", shifttitle = false, pretitle = nothing)::Dendogram
    # get the widths, spacing between branching points of the dendogram's line
    length(dendos) == 1 && return dendos[1]

    if length(dendos) > 2
        widths = collect(
            map(
                d -> if d[1] == 1
                    d[2].measure.w - 1
                else
                    d[2].measure.w + adjust_width(dendos[d[1] - 1], d[2]) - 1
                end,
                enumerate(dendos),
            ),
        )[2:end]
    else
        d1, d2 = dendos
        widths = (d1.measure.w - d1.midpoint) + d2.midpoint
    end

    # get elements of linking line
    line = get_row(BOXES[:SQUARE], widths, :top)
    line, midpoint = replace_line_midpoint(line; widths = widths .+ 1)
    LINES_STYLE = TERM_THEME[].dendo_lines
    TITLE_STYLE = TERM_THEME[].dendo_title

    title = if shifttitle
        pad(apply_style(title, TITLE_STYLE * " dim"), textwidth(line) - 5, :center) * " "^5
    else
        pad(apply_style(title, TITLE_STYLE), textwidth(line), :center)
    end
    space = " "^(dendos[1].midpoint)

    # ensure all elements have the right width
    width = sum(map(d -> d.measure.w, dendos)) - length(space)
    line = pad(line, width, :left)
    title = pad(title, width, :left)

    # create dendogram's segments
    segments = Segment[
        Segment(space * title),
        Segment(space * line, LINES_STYLE),
        *(dendos...).segments...,
    ]

    # add 'pretitle' lines (for expressions only)
    if !isnothing(pretitle)
        pretitle = str_trunc(pretitle, CELLWIDTH)
        l(txt) = fint(midpoint - textwidth(txt) / 2) + length(space)
        r(txt) = cint((width - midpoint - textwidth(txt) / 2))
        prepend!(
            segments,
            [
                Segment(
                    " "^l(pretitle) * pretitle * " "^r(pretitle),
                    TERM_THEME[].dendo_pretitle,
                ),
                Segment(" "^l("⋀") * "⋀" * " "^r("⋀"), "$LINES_STYLE bold"),
                Segment(
                    " "^l(BOXES[:SQUARE].bottom.vertical) *
                    BOXES[:SQUARE].bottom.vertical *
                    " "^r(BOXES[:SQUARE].bottom.vertical),
                    "$LINES_STYLE dim",
                ),
            ],
        )
    end

    return Dendogram(segments, Measure(segments), midpoint + length(space))
end

# ----------------------------------- utils ---------------------------------- #

"""
    adjust_width(x, y)::Int

Width correction factor.

When creating a link between dendograms, the width of the spacing
between branches of the dendogram line needs to be adjusted
depending on the type (`Leaf` or `Dendogram`) of the line.
"""
function adjust_width(x, y)::Int
    _x, _y = typeof(x), typeof(y)
    _x == _y && return 0
    _x == Dendogram && return y.midpoint
    return -x.midpoint
end

"""
    replace_line_midpoint(line::String; widths=nothing)

Replace the mid character of a dendogram tree line with a vertical line for the title.

If the mid character is also the location of a branch (one of the entries in `widths`),
then use the appropriate double branching character.
"""
function replace_line_midpoint(line::String; widths = nothing)
    w1 = prevind(line, rint(ncodeunits(line) / 2) - 1)
    w2 = nextind(line, rint(ncodeunits(line) / 2) + 1)

    char = BOXES[:SQUARE].bottom.vertical
    isnothing(widths) ||
        (textwidth(line[1:w1]) in widths && (char = BOXES[:SQUARE].row.vertical))
    line = line[1:w1] * char * line[w2:end]
    return line, length(line[1:w1])
end

end
