module tree
import Parameters: @with_kw
import MyterialColors: yellow, orange, red, blue

import Term.layout: vstack
import Term: loop_last, replace_double_brackets, escape_brackets, fillin, highlight
import Term.segment: Segment
import Term.measure: Measure
import Term.renderables: AbstractRenderable
import Term.style: apply_style

export Tree


# ---------------------------------------------------------------------------- #
#                                    GUIDES                                    #
# ---------------------------------------------------------------------------- #

treeguides = Dict(
    :standardtree =>("    ", "│   ", "├── ", "└── "),
    :boldtree =>("    ", "┃   ", "┣━━ ", "┗━━ "),
    :asciitree =>("    ", "|   ", "+-- ", "`-- "),
)

"""
    TreeGuides

Store strings to make up a `Tree`'s guides (the line elements showing connections).
"""
struct TreeGuides
    space::String
    vline::String
    branch::String
    leaf::String
end

"""
    TreeGuides(guide_stype::Symbol, style::String)

Get tree guides with style information applied
"""
TreeGuides(guide_stype::Symbol, style::String) = TreeGuides(
    map(
        (g)->apply_style(g, style), 
        treeguides[guide_stype]
    )...
)


# ---------------------------------------------------------------------------- #
#                                     TREE                                     #
# ---------------------------------------------------------------------------- #

# ----------------------------------- leaf ----------------------------------- #

"""
    asleaf

Style an object to render it as a a string
"""
function asleaf end

asleaf(x) = highlight(x)
asleaf(x::AbstractVector) = (replace_double_brackets ∘ escape_brackets ∘ string)(x)

"""
    Leaf

End items in a `Tree`. No sub-trees.
"""
struct Leaf
    name::String
    text::String
end

# ----------------------------------- tree ----------------------------------- #
"""
    Tree

A tree is composed of nodes (other trees) and leaves (end items).
It renders as a hierarchical structure with lines (guides) connecting the various elements
"""
@with_kw struct Tree <: AbstractRenderable
    segments::Union{Nothing, Vector{Segment}} = nothing
    measure::Union{Nothing, Measure} = nothing

    name::String
    level::Int
    nodes::Vector{Tree}
    leaves::Vector{Leaf}

    title_style::String = "italic $red underline bold"
    node_style::String = yellow
    leaf_style::String = "white"
    guide_style::String = "$blue"
    guide_stype::Symbol = :standardtree
end

"""
Show/render a `Tree`
"""
function Base.show(io::IO, tree::Tree) 
    if io != stdout
        print(io, "Tree: $(length(tree.nodes)) nodes, $(length(tree.leaves)) leaves")
    else
        for seg in tree.segments
            println(io, seg)
        end
    end
end


"""
    Tree(data::Union{Dict, Pair}; level=0, title::String="tree", kwargs...)

Construct a `Tree` out of a `Dict`. Recursively handle nested `Dict`s.
"""
function Tree(data::Union{Dict, Pair}; level=0, title::String="tree", kwargs...)
    # initialize
    nodes::Vector{Tree} = []
    leaves::Vector{Leaf} = []

    # go over all entries
    for (k, v) in zip(keys(data), values(data))
        if v isa Dict
            push!(nodes, Tree(v; level=level+1, title=string(k)))
        elseif v isa Pair
            push!(leaves, Leaf(v.first, asleaf(v.second)))
        else
            push!(leaves, Leaf(k, asleaf(v)))
        end
    end

    # if we're handling the first tree, render it. Otherwise parse nested trees.
    if level > 0
        # we don't need to render
        return Tree(name=title, level=level, nodes=nodes, leaves=leaves)
    else
        # render and get measure
        segments = render(Tree(name=title, level=level, nodes=nodes, leaves=leaves))
        measure = Measure(segments)

        return Tree(
            segments=segments, 
            measure=measure, 
            name=title, 
            level=level, 
            nodes=nodes, 
            leaves=leaves,
            kwargs...)
    end
end

# ---------------------------------- render ---------------------------------- #

"""
    render(tree::Tree)::Vector{Segment}

Render a `Tree` into segments. Recursively handle nested trees.


"""
function render(tree::Tree; prevguides::String="", lasttree=false, waslast=[])::Vector{Segment}
    guides = getguides(tree.guide_stype, tree.guide_style)
    hasleaves = length(tree.leaves) > 0

    segments::Vector{Segment}=[]

    """
        Add a segment to the segments vector
    """
    function _add(x::String, style)
        push!(segments, Segment(x, style))
    end
    _add(x::String) = _add(x, "default")

    # ------------------------------ render in parts ----------------------------- #
    # render initial part
    if tree.level == 0
        _add(tree.name, tree.title_style)
    else
        _pre_guides = ""
        for (n, (l, last)) in enumerate(loop_last(waslast))
            # ugly, get the correct sequence of guides based on where we are/what came before
            if last
                _end = lasttree ? guides.leaf : guides.branch
                _pre_guides *= l ? _end : guides.space

            else
                _end = n == length(waslast) ? guides.branch : guides.vline
                _pre_guides *= lasttree ? guides.leaf : _end
            end
        end

        _add(_pre_guides * "[$(tree.node_style)]$(tree.name)[/$(tree.node_style)]")
    end
    tree.level == 0 && _add(prevguides * guides.vline)

    # render sub-trees
    for (last, node) in loop_last(tree.nodes)
        # check if it's the last entry in the tree
        lasttree = last && !hasleaves
        
        # get the appropriate guides
        if lasttree
            prev = prevguides * guides.space
        else
            prev = prevguides * guides.vline
        end

        append!(segments, render(node; prevguides=prev, lasttree=lasttree, waslast=vcat(waslast, lasttree)))
        hasleaves && _add(prevguides * guides.vline)
    end

    # render leaves
    if hasleaves
        for (last, leaf) in loop_last(tree.leaves)
            seg = last ? guides.leaf : guides.branch
            k = "[$(tree.node_style) dim]$(leaf.name)[/$(tree.node_style) dim]"
            v = "[$(tree.leaf_style)]$(leaf.text)[/$(tree.leaf_style)]"
            _add(prevguides * seg * "$k: $v")
        end
    end

    return fillin(segments)
end



end