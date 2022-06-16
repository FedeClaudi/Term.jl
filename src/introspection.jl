module Introspection

using InteractiveUtils

import MyterialColors: orange, grey_dark, light_green

import Term:
    highlight,
    escape_brackets,
    join_lines,
    unescape_brackets,
    split_lines,
    do_by_line,
    expr2string,
    DEFAULT_WIDTH

import ..Panels: Panel
import ..Dendograms: Dendogram
import ..Trees: Tree

include("_inspect.jl")

export inspect, typestree, expressiontree

# ---------------------------------------------------------------------------- #
#                                TYPES HIERARCHY                               #
# ---------------------------------------------------------------------------- #

typestree(io::IO, T::DataType) = print(
    io,
    Panel(
        Tree(T);
        title = "Types hierarchy",
        style = "blue dim",
        title_style = orange * " default",
        title_justify = :right,
        fit = true,
        padding = (1, 4, 1, 1),
    ),
)

typestree(T::DataType) = typestree(stdout, T)

function expressiontree(io::IO, e::Expr)
    _expr = expr2string(e)
    tree = Tree(e)

    return print(
        io,
        Panel(
            tree;
            title = _expr,
            title_style = "$light_green default bold",
            title_justify = :center,
            style = grey_dark,
            fit = tree.measure.w > DEFAULT_WIDTH[],
            width = max(tree.measure.w, DEFAULT_WIDTH[]),
            subtitle = "inspect",
            subtitle_justify = :right,
            justify = :center,
            padding = (1, 1, 1, 1),
        ),
    )
end
expressiontree(e::Expr) = expressiontree(stdout, e)

# ---------------------------------------------------------------------------- #
#                                EXPR. DENDOGRAM                               #
# ---------------------------------------------------------------------------- #

function inspect(io::IO, expr::Expr)
    _expr = expr2string(expr)
    dendo = Dendogram(expr)

    return print(
        io,
        Panel(
            dendo;
            title = _expr,
            title_style = "$light_green default bold",
            title_justify = :center,
            style = grey_dark,
            fit = true,
            # width=dendo.measure.w,
            subtitle = "inspect",
            subtitle_justify = :right,
            justify = :center,
            padding = (1, 1, 1, 1),
        ),
    )
end

end
