module Trees

import AbstractTrees: repr_tree, TreeCharSet, children
using InteractiveUtils

import Term: replace_multi, highlight, reshape_text, cleantext, TERM_THEME, Theme

import ..Renderables: AbstractRenderable, RenderableText
import ..Style: apply_style
import ..Segments: Segment
import ..Measures: Measure
import ..Panels: Panel

export Tree

# ---------------------------------------------------------------------------- #
# copied from AbstractTrees.jl

function print_tree(
        printnode::Function, print_child_key::Function, io::IO, node;
        maxdepth::Integer = 5,
        indicate_truncation::Bool = true,
        charset::TreeCharSet = TreeCharSet(),
        printkeys::Union{Bool, Nothing} = nothing,
        depth::Integer = 0,
        prefix::AbstractString = "",
        printnode_kw = (;)
    )
    # Get node representation as string
    buf = IOBuffer()
    printnode(IOContext(buf, io), node; printnode_kw...)
    str = String(take!(buf))

    depth == 0 && print(io, prefix)  # [Term.jl change] added prefix

    # Copy buffer to output, prepending prefix to each line
    for (i, line) in enumerate(split(str, '\n'))
        i ≠ 1 && print(io, prefix)
        println(io, line)
    end

    # Node children
    c = children(node)

    # No children?
    isempty(c) && return

    # Reached max depth?
    if depth ≥ maxdepth
        # Print truncation char(s)
        if indicate_truncation
            println(io, prefix, charset.trunc)
            println(io, prefix)
        end
        return
    end

    # Print keys?
    this_printkeys = applicable(keys, c) && (isnothing(printkeys) ? shouldprintkeys(c) : printkeys)

    # Print children
    s = Iterators.Stateful(this_printkeys ? pairs(c) : c)

    while !isempty(s)
        child_prefix = prefix

        if this_printkeys
            child_key, child = popfirst!(s)
        else
            child = popfirst!(s)
            child_key = nothing
        end

        print(io, prefix)

        # Last child?
        if isempty(s)
            print(io, charset.terminator)
            child_prefix *= " "^(textwidth(charset.skip) + textwidth(charset.dash) + 1)
        else
            print(io, charset.mid)
            child_prefix *= charset.skip * " "^(textwidth(charset.dash) + 1)
        end

        print(io, charset.dash, ' ')

        # Print key
        if this_printkeys
            print_child_key(IOContext(buf, io), child_key)
            key_str = String(take!(buf))

            print(io, key_str, charset.pair)

            # [Term.jl change] added `cleantext`
            child_prefix *= " "^(textwidth(cleantext(key_str)) + textwidth(charset.pair))
        end

        print_tree(
            printnode, print_child_key, io, child;
            maxdepth, indicate_truncation, charset = charset,
            printkeys, depth = depth + 1, prefix = child_prefix,
            printnode_kw
        )
    end
    return
end

print_tree(printnode::Function, io::IO, node; kw...) = print_tree(printnode, print_child_key, io, node; kw...)
print_tree(io::IO, node; kw...) = print_tree(printnode, print_child_key, io, node; kw...)
print_tree(node; kw...) = print_tree(stdout, node; kw...)
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
#                                    GUIDES                                    #
# ---------------------------------------------------------------------------- #

treeguides = Dict(
    :standardtree => TreeCharSet("├", "└", "│", "─", "⋮", " ⇒ "),
    :roundedtree => TreeCharSet("├──", "╰─", "│", "─", "⋮", " ⇒ "),
    :boldtree => TreeCharSet("┣━━", "┗━━", "┃", "━", "⋮", " ⇒ "),
    :asciitree => TreeCharSet("+--", "`--", "|", "--", "...", " => "),
)

# ---------------------------------------------------------------------------- #
#                                     TREE                                     #
# ---------------------------------------------------------------------------- #

const _TREE_PRINTING_TITLE = Ref{Union{Nothing, String}}(nothing)

"""
    print_node(io, node; kw...)

Core function to enable fancy tree printing. Styles the leaf/key of each node.
"""
function print_node(io, node; kw...)
    theme::Theme = TERM_THEME[]
    if isnothing(_TREE_PRINTING_TITLE[])  # print node
        styled = if node isa AbstractString
            highlight(node, :string; theme)
        else
            highlight(string(node); theme)
        end
        print(io, reshape_text(styled, theme.tree_max_leaf_width))
    else  # print title
        title = _TREE_PRINTING_TITLE[]
        print(io, apply_style(title, theme.tree_title))
    end

    return _TREE_PRINTING_TITLE[] = nothing
end

"""
    print_key(io, k; kw...)

Print a tree's node's key with some style.
"""
function print_key(io, k; kw...)
    s = TERM_THEME[].tree_keys
    return print(io, apply_style("{s}" * string(k) * "{/s}"))
end

"""
    style_guides(tree::String, guides::TreeCharSet, theme::Theme)

Apply style to a tree's guides by inserting it into its string representation.
Not ideal as it will affect the style of other elements with the same characters
like Panels, but ok for no.
"""
function style_guides(tree::String, guides::TreeCharSet, theme::Theme)
    return replace_multi(
        tree,
        guides.mid => apply_style(guides.mid, theme.tree_mid),
        guides.terminator => apply_style(guides.terminator, theme.tree_terminator),
        guides.skip => apply_style(guides.skip, theme.tree_skip),
        guides.dash => apply_style(guides.dash, theme.tree_dash),
        guides.trunc => apply_style(guides.trunc, theme.tree_trunc),
        strip(guides.pair) => apply_style(string(strip(guides.pair)), theme.tree_pair)
    )
end

"""
    Tree

Renderable tree.
"""
struct Tree <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
end

"""
    Tree(
        tree;
        guides::Union{TreeCharSet,Symbol} = :standardtree,
        theme::Theme = TERM_THEME[],
        printkeys::Union{Nothing,Bool} = true,
        print_node_function::Function = print_node,
        print_key_function::Function = print_key,
        title::Union{String, Nothing}=nothing,
        prefix::String = "  ",
        kwargs...,
    )

Constructor for `Tree`

It uses `AbstractTrees.repr_tree` to get a string representation of `tree` (any object
compatible with the `AbstractTrees` packge). Applies style to the string and creates a
renderable `Tree`.

Arguments:
- `tree`: anything compatible with `AbstractTree`
- `guides`: if a symbol, the name of preset tree guides types. Otherwise an instance of
    `AbstractTrees.TreeCharSet`
- `theme`: `Theme` used to set tree style.
- `printkeys`: If `true` print keys. If `false` don't print keys.
- `print_node_function`: Function used to print nodes.
- `print_key_function`: Function used to print keys.
- `title`: Title of the tree.
- `prefix`: Prefix to be used in `AbstractTrees.repr_tree`


For other kwargs look at `AbstractTrees.repr_tree`
"""
function Tree(
        tree;
        guides::Union{TreeCharSet, Symbol} = :standardtree,
        theme::Theme = TERM_THEME[],
        printkeys::Union{Nothing, Bool} = true,
        print_node_function::Function = print_node,
        print_key_function::Function = print_key,
        title::Union{String, Nothing} = nothing,
        prefix::String = "  ",
        context = nothing,
        kwargs...,
    )
    _TREE_PRINTING_TITLE[] = title
    _theme = TERM_THEME[]
    TERM_THEME[] = theme

    # print tree
    guides = guides isa Symbol ? treeguides[guides] : guides
    tree = repr_tree(
        print_node_function,
        print_key_function,
        tree;
        charset = guides,
        printkeys,
        prefix,
        context,
        kwargs...,
    )

    # style keys
    rx = Regex("(?<=$(guides.dash)) [\\w.,\":\\[\\]\\d]+ (?=$(strip(guides.pair)))")
    tree = replace(
        tree,
        rx => SubstitutionString(
            "{$(theme.tree_keys)}" * s"\g<0>" * "{/$(theme.tree_keys)}",
        ),
    )

    # style guides
    tree = style_guides(tree, guides, theme)

    # turn into a renderable
    rt = RenderableText(tree)

    # restore theme
    TERM_THEME[] = _theme
    return Tree(rt.segments, rt.measure)
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
    Tree(T::DataType; prefix = "", kwargs...)::Tree

Construct a `Tree` visualization of `T`'s types hierarchy
The key is in costructing the actual hierarchy tree recursively.
"""
function Tree(T::DataType; prefix = "", kwargs...)::Tree
    # create a dictionary of types hierarchy
    subs = Dict(string(s) => nothing for s in subtypes(T))
    data = make_hierarchy_dict(supertypes(T), T, subs)

    # define a fn to avoid printing nodes
    s = TERM_THEME[].tree_mid
    print_node_datatype(io::IO, x) = begin
        if length(children(x)) > 0
            print(io, apply_style("{$s}┬{/$s}"))
        else
            print(io, "")
        end
    end

    # change style of pair
    _old_style = TERM_THEME[].tree_pair
    TERM_THEME[].tree_pair = "hidden"

    # print tree
    _tree = Tree(
        data;
        printkeys = true,
        print_node_function = print_node_datatype,
        print_key_function = print_key,
        prefix,
        kwargs...
    )
    TERM_THEME[].tree_pair = _old_style

    return _tree
end

end
