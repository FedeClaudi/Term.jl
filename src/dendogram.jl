module dendogram

import Term: fint, int, truncate, loop_firstlast, highlight, textlen

import ..box: get_rrow, get_lrow, get_row, SQUARE
import ..layout: pad
import ..segment: Segment
import ..measure: Measure
import ..renderables: AbstractRenderable
import ..style: apply_style

import MyterialColors: yellow, salmon, blue_light, green_light, salmon_light

export Dendogram, link, ⊗

# ----------------------------------- leaf ----------------------------------- #
struct Leaf
    text::String
    midpoint::Int
end

function Leaf(leaf; cellwidth=11)
    leaf = string(leaf)
    if textlen(leaf) > cellwidth
        leaf = truncate(leaf, cellwidth)
    else
        leaf = pad(leaf, cellwidth+1, :center)
    end


    midpoint = fint(textlen(leaf)/2)
    return Leaf(leaf, midpoint)
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

function Dendogram(e::Expr; cellwidth=9, spacing=1)
    # get leaves
    leaves = Leaf.(e.args[2:end]; cellwidth=cellwidth)
    leaves_line = join(
        map(
            nl -> string(nl[3], nl[1], nl[2], spacing), 
            loop_firstlast(leaves)
            )
        )
    width = textlen(leaves_line)

    # get Tree structure
    if length(leaves) > 1
        widths = repeat([cellwidth+1 + spacing], length(leaves)-1)

        line = get_row(SQUARE, widths, :top)
        w1 = prevind(line, int(ncodeunits(line)/2)-1)
        w2 = nextind(line, int(ncodeunits(line)/2)+1)
        line = line[1:w1] * SQUARE.bottom.vertical * line[w2:end]
        line = pad(line, width, :center)
    else
        widths = [cellwidth]
        w1 = int(widths[1]/2)
        line = pad(string(SQUARE.bottom.vertical), cellwidth, :center)
    end

    # get title
    title = pad(apply_style("$(e.head): [bold underline $salmon]$(e.args[1])[/bold underline $salmon]", salmon_light), width, :center)

    # put together
    segments = [
        Segment(title),  
        Segment(line, yellow),
        Segment(leaves_line, blue_light)

    ]

    return Dendogram(segments, Measure(segments), int(width/2))
end



function link(dendros...; title="")::Dendogram
    length(dendros) == 1 && return dendros[1]

    widths = diff(  
        collect(cumsum(
            map(d->d.midpoint * 2 - 1, dendros)
            ))
    )
    width = sum(map(d->d.measure.w, dendros))
    line = get_row(SQUARE, widths, :top)
    w1 = prevind(line, int(ncodeunits(line)/2)-1)
    w2 = nextind(line, int(ncodeunits(line)/2)+1)
    line = line[1:w1] * SQUARE.bottom.vertical * line[w2:end]
    line = pad(line, width, :center)

    segments::Vector{Segment} = [
        Segment(pad(apply_style(title, salmon * " bold underline"), width, :center)),  
        Segment(line, yellow), 
        *(dendros...).segments...
    ]

    return Dendogram(segments, Measure(segments), fint(width/2))
end

⊗(dendros...) = link(dendros...)



end