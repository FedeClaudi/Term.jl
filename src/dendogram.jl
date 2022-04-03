module dendogram

import Term: fint, int, truncate, loop_firstlast, highlight, textlen

import ..box: get_rrow, get_lrow, get_row, SQUARE
import ..layout: pad
import ..segment: Segment
import ..measure: Measure
import ..renderables: AbstractRenderable
import ..style: apply_style

import MyterialColors: yellow, salmon, blue_light, green_light, salmon_light

export Dendogram, link


const LEAVES_STYLE = yellow
const LINES_STYLE = blue_light * " dim bold"
const CELLWIDTH = 8
const SPACING = 1

# ----------------------------------- leaf ----------------------------------- #
struct Leaf <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
    text::String
    midpoint::Int
end

function Leaf(leaf)
    leaf = string(leaf)
    if textlen(leaf) > CELLWIDTH
        leaf = truncate(leaf, CELLWIDTH)
    else
        leaf = pad(leaf, CELLWIDTH+1, :center)
    end

    midpoint = fint(textlen(leaf)/2)
    leaf = replace(leaf, ' ' => '_')

    seg = Segment(" "*leaf*" ", LEAVES_STYLE)
    return Leaf([seg], Measure(seg), leaf, midpoint)
end

function Base.string(leaf::Leaf, isfirst::Bool, islast::Bool, spacing::Int)
    l = isfirst ? "" : " "^spacing
    r = islast ? "" : " "^spacing
    return l * leaf.text * r
end

# --------------------------------- dendogram -------------------------------- #

struct Dendogram <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
    midpoint::Int  # width of 'center'
end

function Dendogram(head, args::Vector; first_arg=nothing)
    # get leaves
    leaves = Leaf.(args)
    leaves_line = join(
        map(
            nl -> string(nl[3], nl[1], nl[2], SPACING), 
            loop_firstlast(leaves)
            )
        )
    width = textlen(leaves_line)

    # get Tree structure
    if length(leaves) > 1
        widths = repeat([CELLWIDTH+1 + SPACING], length(leaves)-1)

        line = get_row(SQUARE, widths, :top)
        line = pad(replace_line_midpoint(line), width, :center)
    else
        widths = [CELLWIDTH]
        w1 = int(widths[1]/2)
        line = pad(string(SQUARE.bottom.vertical), CELLWIDTH, :center)
    end

    # get title
    if isnothing(first_arg)
        _title = ""
    else 
        _title = ": [bold underline $salmon]$first_arg[/bold underline $salmon]"
    end
    title = pad(apply_style("$(head)$_title", salmon_light), width, :center)

    # put together
    segments = [
        Segment(title),  
        Segment(line, LINES_STYLE),
        Segment(leaves_line, LEAVES_STYLE)
    ]

    return Dendogram(segments, Measure(segments), int(width/2))
end


function Dendogram(e::Expr)
    length(e.args) == 1 && return Dendogram(e.head, e.args)
    
    # if there's no more nested expressions, return a dendogram
    !any(isa.(e.args[2:end], Expr)) && return Dendogram(e.head, e.args[2:end]; first_arg=e.args[1])

    # recursively get leaves
    leaves = map(
        arg -> arg isa Expr ? Dendogram(arg) : Leaf(arg),
        e.args[2:end]
    )
    # make dendogram
    title = apply_style("$(e.head): [bold underline $salmon]$(e.args[1])[/bold underline $salmon]", salmon_light)
    return link(leaves...; title=title)
end



function adjust_width(x, y)::Int
    _x, _y = typeof(x), typeof(y)
    _x == _y && return 0
    _x == Dendogram && return y.midpoint
    return -x.midpoint
end


function replace_line_midpoint(line::String; widths=nothing)::String
    w1 = prevind(line, int(ncodeunits(line)/2)-1)
    w2 = nextind(line, int(ncodeunits(line)/2)+1)

    char=SQUARE.bottom.vertical
    if !isnothing(widths)
        if textwidth(line[1:w1]) in widths
            char = SQUARE.row.vertical
        end
    end
    line = line[1:w1] * char * line[w2:end]
end

function link(dendos...; title="")::Dendogram
    length(dendos) == 1 && return dendos[1]
    
    if length(dendos) > 2
        widths = collect(map(
            d -> d[1] == 1 ?
                d[2].measure.w -1  :
                d[2].measure.w + adjust_width(dendos[d[1]-1], d[2]) - 1,

            enumerate(dendos)
        ))[2:end]
    else
        d1, d2 = dendos
        widths = (d1.measure.w- d1.midpoint) + d2.midpoint # + CELLWIDTH - 2*SPACING
    end

    # get elements of linking line
    line = get_row(SQUARE, widths, :top)
    line = replace_line_midpoint(line; widths = widths .+ 1)
    title = pad(apply_style(title, salmon * " bold"), textwidth(line), :center)
    space = " "^(dendos[1].midpoint + 1)

    # ensure all elements have the right width
    width = sum(map(d -> d.measure.w, dendos)) - length(space)
    line = pad(line, width, :left)
    title = pad(title, width, :left)

    # create dendogram
    segments::Vector{Segment} = [
        Segment(space * title),  
        Segment(space * line, LINES_STYLE,), 
        *(dendos...).segments...
    ]

    return Dendogram(segments, Measure(segments), fint(length(line)/2 + dendos[1].midpoint))
end




end