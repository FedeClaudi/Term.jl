module Trees

import MyterialColors: yellow, orange, red, blue
import OrderedCollections: OrderedDict
import Base: @kwdef

using InteractiveUtils

import Term:
    loop_last,
    escape_brackets,
    fillin,
    highlight,
    rint,
    TERM_THEME,
    textlen,
    str_trunc,
    expr2string

import ..Renderables: AbstractRenderable
import ..Layout: vstack, pad, hLine
import ..Style: apply_style
import ..Segments: Segment
import ..Measures: Measure
import ..Panels: Panel

export Tree

# ---------------------------------------------------------------------------- #
#                                    GUIDES                                    #
# ---------------------------------------------------------------------------- #

treeguides = Dict(
    :standardtree => ("    ", "│   ", "├── ", "└── "),
    :boldtree => ("    ", "┃   ", "┣━━ ", "┗━━ "),
    :asciitree => ("    ", "|   ", "+-- ", "`-- "),
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
    TreeGuides(guides_type::Symbol, style::String)

Get tree guides with style information applied
"""
TreeGuides(guides_type::Symbol, style::String) =
    TreeGuides(map((g) -> apply_style("{$style}$g{/$style}"), treeguides[guides_type])...)

# ---------------------------------------------------------------------------- #
#                                     TREE                                     #
# ---------------------------------------------------------------------------- #

# ----------------------------------- leaf ----------------------------------- #

"""
    asleaf

Style an object to render it as a a string
"""
function asleaf end

asleaf(x) = str_trunc(highlight(string(x)), TERM_THEME[].tree_max_width)
asleaf(x::Nothing) = nothing
asleaf(x::AbstractVector) = str_trunc(string(x), TERM_THEME[].tree_max_width)
asleaf(x::AbstractString) = str_trunc(highlight(x, :string), TERM_THEME[].tree_max_width)

"""
    Leaf

End items in a `Tree`. No sub-trees.
"""
struct Leaf
    name::Union{Nothing,String}
    text::Union{Nothing,String}
    idx::Int  # rendering index
end

# ----------------------------------- tree ----------------------------------- #
"""
    Tree

A tree is composed of nodes (other trees) and leaves (end items).
It renders as a hierarchical structure with lines (guides) connecting the various elements
"""
@kwdef struct Tree <: AbstractRenderable
    segments::Union{Nothing,Vector{Segment}} = nothing
    measure::Measure = Measure(segments)

    name::String
    level::Int
    nodes::Vector{Tree}
    leaves::Vector{Leaf}
    idx::Int = 0  # rendering index for tree that are nodes in a lager tree

    title_style::String = TERM_THEME[].tree_title_style
    node_style::String = TERM_THEME[].tree_node_style
    leaf_style::String = TERM_THEME[].tree_leaf_style
    guides_style::String = TERM_THEME[].tree_guide_style
    guides_type::Symbol = :standardtree
end

"""
Show/render a `Tree`
"""
function Base.show(io::IO, tree::Tree)
    if io != stdout
        print(
            io,
            "Tree: $(length(tree.nodes)) nodes, $(length(tree.leaves)) leaves | Idx: $(tree.idx)",
        )
    else
        println.(io, tree.segments)
    end
end

"""
Add a new node to an existing tree's nodes or levaes.
"""
function addnode!(nodes::Vector{Tree}, leaves::Vector{Leaf}, level, k, v::AbstractDict)
    return push!(
        nodes,
        Tree(
            v;
            level = level + 1,
            title = str_trunc(string(k), TERM_THEME[].tree_max_width),
            idx = length(nodes) + length(leaves) + 1,
        ),
    )
end

function addnode!(nodes::Vector{Tree}, leaves::Vector{Leaf}, level, k, v::Pair)
    k = if isnothing(v.first)
        nothing
    else
        str_trunc(string(v.first), TERM_THEME[].tree_max_width)
    end
    idx = length(nodes) + length(leaves) + 1
    return push!(leaves, Leaf(k, asleaf(v.second), idx))
end

function addnode!(nodes::Vector{Tree}, leaves::Vector{Leaf}, level, k, v::Any)
    k = isnothing(k) ? nothing : str_trunc(string(k), TERM_THEME[].tree_max_width)
    idx = length(nodes) + length(leaves) + 1
    return push!(leaves, Leaf(k, asleaf(v), idx))
end

function addnode!(nodes::Vector{Tree}, leaves::Vector{Leaf}, level, k, v::Vector)
    for _v in v
        _k =
            _v isa Union{Dict,OrderedDict} ? collect(keys(_v))[1] :
            (v isa Pair ? _v.first : v)
        addnode!(nodes, leaves, level + 1, _k, _v)
    end
end

"""
    Tree(data::Union{AbstractDict, Pair}; level=0, title::String="tree", kwargs...)

Construct a `Tree` out of a `AbstractDict`. Recursively handle nested `AbstractDict`s.
"""
function Tree(
    data::Union{AbstractDict,Pair,Vector};
    level = 0,
    title::String = "tree",
    kwargs...,
)

    # initialize
    nodes::Vector{Tree} = []
    leaves::Vector{Leaf} = []

    # go over all entries
    for (k, v) in zip(keys(data), values(data))
        addnode!(nodes, leaves, level, k, v)
    end

    # if we're handling the first tree, render it. Otherwise parse nested trees.
    if level > 0
        # we don't need to render
        return Tree(;
            name = title,
            level = level,
            nodes = nodes,
            leaves = leaves,
            kwargs...,
        )
    else
        # render and get measure
        segments = render(
            Tree(; name = title, level = level, nodes = nodes, leaves = leaves, kwargs...),
        )
        measure = Measure(segments)

        return Tree(;
            segments = segments,
            measure = measure,
            name = str_trunc(title, TERM_THEME[].tree_max_width),
            level = level,
            nodes = nodes,
            leaves = leaves,
            kwargs...,
        )
    end
end

# ---------------------------------- render ---------------------------------- #

"""
    render(tree::Tree)::Vector{Segment}

Render a `Tree` into segments. Recursively handle nested trees.


"""
function render(
    tree::Tree;
    prevguides::String = "",
    lasttree = false,
    waslast = [],
    guides = nothing,
)::Vector{Segment}
    guides = isnothing(guides) ? TreeGuides(tree.guides_type, tree.guides_style) : guides
    hasleaves = length(tree.leaves) > 0

    segments::Vector{Segment} = []

    """
        Add a segment to the segments vector
    """
    _add(x::String, style) = push!(segments, Segment(x, style))
    _add(x::String) = _add(x, "default")

    # ------------------------------ render in parts ----------------------------- #
    # render initial part
    if tree.level == 0
        header_text = "{$(tree.title_style)}$(tree.name){/$(tree.title_style)}"
        header =
            (" " * header_text * " ") /
            hLine(textlen(tree.name) + 2; style = "$(tree.title_style) dim", box = :HEAVY)

        append!(segments, header.segments)
    else
        _pre_guides = ""
        for (n, (l, last)) in enumerate(loop_last(waslast))
            # ugly, get the correct sequence of guides based on where we are/what came before
            if last
                _end = lasttree ? guides.leaf : guides.branch
                _pre_guides *= l ? _end : guides.space

            else
                _end = n == length(waslast) ? guides.branch : guides.vline
                _pre_guides *= lasttree ? (l ? guides.leaf : guides.vline) : _end
            end
        end

        _add(_pre_guides * "{$(tree.node_style)}$(tree.name){/$(tree.node_style)}")
    end
    tree.level == 0 && _add(prevguides * guides.vline)

    # get all nodes and sub-trees in order for rendering
    elements = vcat(tree.nodes, tree.leaves)
    idxs = getfield.(elements, :idx)
    elements = elements[sortperm(idxs)]
    # @info "rendering $(length(elements)) elements" elements

    for (last, elem) in loop_last(elements)
        if elem isa Tree
            prev = prevguides * (last ? guides.space : guides.vline)

            append!(
                segments,
                render(
                    elem;
                    prevguides = prev,
                    lasttree = last,
                    waslast = vcat(waslast, last), # vcat(waslast, lasttree),
                    guides = guides,
                ),
            )
            # hasleaves && length(elem.leaves) > 0 && _add(prevguides * guides.vline)
        elseif elem isa Leaf
            # @info "rendering leaf $(elem.idx): $(elem.name) > $(elem.text)"
            seg = last ? guides.leaf : guides.branch
            if isnothing(elem.text)
                k = isnothing(elem.name) ? "" : highlight(elem.name)
                v = ""
            else
                k = if isnothing(elem.name)
                    ""
                else
                    "{$(tree.leaf_style)}$(elem.name){/$(tree.leaf_style)}: "
                end
                v = elem.text
            end
            _add(prevguides * seg * k * v)
        end
    end

    # left pad segments
    if tree.level == 0
        header_length = length(header.segments)
        padded_segments = vcat(
            header.segments...,
            pad(segments[(header_length + 1):end], rint(header.measure.w / 2 - 1))...,
        )
        return fillin(padded_segments)
    else
        return segments
    end
end

# ---------------------------------------------------------------------------- #
#                                HIERARCHY TREE                                #
# ---------------------------------------------------------------------------- #
"""
Apply style for the type whose hierarchy Tree we are making
"""
style_T(T) = "{orange1 italic underline}$T{/orange1 italic underline}"

"""
    make_hierarchy_dict(x::Vector{DataType}, T::DataType, Tsubs::AbstractDict)::AbstractDict

Recursively create a dictionary with the types hierarchy for `T`.
`Tsubs` carries information about T's subtypes.
The AbstractDict is made backwards. From  the deepest levels up.
"""
function make_hierarchy_dict(x::NTuple, T::DataType, Tsubs::AbstractDict)::AbstractDict
    data = Dict()
    prev = ""
    for (n, y) in enumerate(x)
        if n == 1
            continue
        elseif n < length(x)
            subs = Dict()
            for s in subtypes(y)
                if s == T
                    subs[style_T(s)] = Tsubs
                else
                    subs[string(s)] = nothing
                end
            end

            if n == 2
                data = subs
            else
                subs[prev] = data
                data = subs
            end

            prev = string(y)
        end
    end
    return data
end

"""
    Tree(T::DataType)::Tree

Construct a `Tree` visualization of `T`'s types hierarchy
"""
function Tree(T::DataType)::Tree
    # create a dictionary of types hierarchy
    subs = Dict(string(s) => nothing for s in subtypes(T))
    data = make_hierarchy_dict(supertypes(T), T, subs)

    return Tree(
        data;
        # title=string(supertypes(T)[end]),
        title = "Any",
        title_style = "bright_green italic",
        guides_style = "green dim",
    )
end

function _key(e::Expr)
    if length(e.args) > 1
        "$(expr2string(e))  {dim blue}($(e.head): {/dim blue}{red bold default}$(e.args[1]){/red bold default}{dim blue}){/dim blue}"
    else
        string(e.head)
    end
end
_values(e::Expr) = length(e.args) > 1 ? e.args[2:end] : e.args

_pair(x) = nothing => x
_pair(e::Expr) = Dict(_key(e) => _pair.(_values(e)))

function Tree(expr::Expr; kwargs...)
    parsed = _pair(expr)
    parsed = Dict(collect(keys(parsed))[1] => parsed)
    return Tree(parsed; title = expr2string(expr))
end

end
