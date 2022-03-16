import Parameters: @with_kw
import MyterialColors: yellow, orange, red, blue

import Term.layout: vstack
import Term: loop_last, replace_double_brackets, escape_brackets
import Term.segment: Segment
import Term.measure: Measure
import Term.renderables: AbstractRenderable


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


asleaf(x) = (replace_double_brackets ∘ escape_brackets ∘ string)(x)

"""
    Tree(data::Union{Dict, Pair}; level=0, title::String="tree", kwargs...)

Construct a `Tree` out of a `Dict`. Recursively handle nested `Dict`s.
"""
function Tree(data::Union{Dict, Pair}; level=0, title::String="tree", kwargs...)
    # initialize
    nodes::Vector{Tree} = []
    leaves::Vector{Leaf} = []
    # data = data isa Pair ? Dict(data) : data

    # go over all entries
    for (k, v) in zip(keys(data), values(data))
        if v isa Dict
            push!(nodes, Tree(v; level=level+1, title=string(k)))
        elseif v isa Pair
            @info "v isa pair" v
            push!(leaves, Leaf(v.first, asleaf(v.second)))
        else
            @info "v isa" v
            push!(leaves, Leaf(k, asleaf(v)))
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
function render(tree::Tree; prevhasleaves=true, lasttree=false)::Vector{Segment}
    guides = getguides(tree.guide_stype, tree.guide_style)
    hasleaves = length(tree.leaves) > 0
    hasanodes = length(tree.nodes) > 0
    haschildren = hasanodes || hasleaves


    segments::Vector{Segment}=[]
    function _add(x::String, style)
        push!(segments, Segment(x, style))
    end
    _add(x::String) = _add(x, "default")

    # get spacing based on what was before
    if haschildren && !lasttree
        pre = "[$(tree.guide_style)]$(guides.vline^tree.level)[/$(tree.guide_style)]"
    else
        pre = "[$(tree.guide_style)]$(guides.space^tree.level)[/$(tree.guide_style)]"
    end

    # render initial part
    if tree.level == 0
        _add(tree.name, tree.title_style)
    else
        if prevhasleaves && !lasttree
            _pre = guides.vline^(tree.level-1) * guides.branch
        else
            _pre = guides.vline^(tree.level-1) * guides.leaf
        end
        _add(_pre * "[$(tree.node_style)]$(tree.name)[/$(tree.node_style)]")
    end
    tree.level == 0 && _add(pre * guides.vline)

    # render sub-trees
    for (last, node) in loop_last(tree.nodes)
        islast = last && !hasleaves
        append!(segments, render(node; prevhasleaves=haschildren, lasttree=islast))
        hasleaves && _add(pre * guides.vline)
    end

    # render leaves
    if hasleaves
        for (last, leaf) in loop_last(tree.leaves)
            seg = last ? guides.leaf : guides.branch
            k = "[$(tree.node_style) dim]$(leaf.name)[/$(tree.node_style) dim]"
            v = "[$(tree.leaf_style)]$(leaf.text)[/$(tree.leaf_style)]"
            _add(pre * seg * "$k: $v")
        end
    end

    return segments
end


# ---------------------------------------------------------------------------- #
#                                   EXAMPLES                                   #
# ---------------------------------------------------------------------------- #

# d = Dict(
#     "nested" => Dict(
#         "n1"=>1,
#         "n2"=>2,
#     ),  
# )


# d = Dict(
#     "nested" => Dict(
#         "n1"=>1,
#         "n2"=>2,
#     ),  
#     "nested2" => Dict(
#         "n1"=>[1, 2, 3],
#         "n2"=>2,
#     ),  
# )


d = Dict(
    "nested" => Dict(
        "deeper"=>Dict(
            "aleaf"=>"unbeliefable",
            "leaflet"=>"level 3"
        ),
        "n2"=>Int,
        "n3"=>1 + 2,
    ),  
    "nested2" => Dict(
        "n1"=>[1, 2, 3],
        "n2"=>2,
    ),  
)

# ----------------------------------- full ----------------------------------- #

# TODO: allow for nested trees to print out correctly
# TODO: fix misplaced guides
# TODO: fill in widths function

tree = Tree(d)

# import Term: Panel
# pan = Panel(tree; title="A tree", style="dim", fit=true, title_style="bold white", padding=(0, 0, 0, 0))
# print(pan)

print(tree)