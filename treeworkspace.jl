import Parameters: @with_kw
import MyterialColors: yellow, orange, red, blue

import Term.layout: vstack
import Term: loop_last
import Term.segment: Segment
import Term.measure: Measure
import Term.renderables: AbstractRenderable

"""
    iterable(x)

Checks if x is an iterable (but not a string).
"""
function iterable(x)
    x isa AbstractString && return false
    try
        iterate(x)
        return true
    catch
        return false
    end
end

"""
    TreeGuides

Store strings to make up a `Tree`'s guide.
"""
struct TreeGuides
    space::String
    vline::String
    branch::String
    leaf::String
end

treeguides = Dict(
    :standardtree =>("    ", "│   ", "├── ", "└── "),
    :boldtree =>("    ", "┃   ", "┣━━ ", "┗━━ "),
    :asciitree =>("    ", "|   ", "+-- ", "`-- "),
)

getguides(guide_stype::Symbol, style::String) = TreeGuides(
    map(
        (g)->Segment(g, style).text, 
        treeguides[guide_stype]
    )...
)

"""
    Leaf

End items in a `Tree`. No sub-trees.
"""
struct Leaf
    name::String
    text::String
end



"""
    Tree
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
    data = data isa Pair ? Dict(data) : data

    # go over all entries
    for (k, vv) in zip(keys(data), values(data))
        # ensure we can loop over items
        vv = iterable(vv) ? vv : [vv]
        
        # dict -> nodes, others -> leaves
        for v in vv
            if v isa Dict || v isa Pair
                push!(nodes, Tree(v; level=level+1, title=string(k)))
            else
                push!(leaves, Leaf(k, string(v)))
            end
        end
    end

    # done
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

"""
    render(tree::Tree)::Vector{Segment}

Render a `Tree` into segments. Recursively handle nested trees.
"""
function render(tree::Tree)::Vector{Segment}
    guides = getguides(tree.guide_stype, tree.guide_style)

    segments::Vector{Segment}=[]
    _add(x::String,) = push!(segments, Segment(x,))
    _add(x::String, style) = push!(segments, Segment(x, style))

    # get spacing based on what was before
    pre = "[$(tree.guide_style)]$(guides.vline^tree.level)[/$(tree.guide_style)]"


    # render initial part
    if tree.level == 0
        _add(tree.name, tree.title_style)
    else
        _pre = guides.vline^(tree.level-1) * guides.branch
        _add(_pre * "[$(tree.node_style)]$(tree.name)[/$(tree.node_style)]")
    end
    tree.level == 0 && _add(pre * guides.vline)

    # render sub-trees
    for node in tree.nodes
        append!(segments, render(node))
        _add(pre * guides.vline)
    end

    # render leaves
    for (last, leaf) in loop_last(tree.leaves)
        seg = last ? guides.leaf : guides.branch
        _add(pre * seg * "[$(tree.node_style) dim]$(leaf.name)[/$(tree.node_style) dim]: [$(tree.leaf_style)]$(leaf.text)[/$(tree.leaf_style)]")
    end

    return segments
end



d = Dict(
    "deep" => Dict(
        "deeper" => [
                1, 
                2, 
                Dict(
                    "aleaf"=>:x,
                    "anotherleaf"=>1+1,
                )
        ],
        "deep'sleaf"=>"unbeliefable",
    ),
    "name" => "test",
    "aleaf" => 1,

)

# TODO: fix bug with leaves not being assigned correctly...
# TODO: fix widths

tree = Tree(d)

import Term: Panel
pan = Panel(tree; title="A tree", style="dim", fit=true, title_style="bold white", padding=(0, 0, 0, 0))
print(pan)

# print(tree * tree)