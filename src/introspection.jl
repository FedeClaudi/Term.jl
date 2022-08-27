module Introspection

using InteractiveUtils
import InteractiveUtils: supertypes as getsupertypes

import MyterialColors: pink, pink_light, orange, grey_dark, light_green

import Term:
    highlight,
    escape_brackets,
    join_lines,
    unescape_brackets,
    split_lines,
    do_by_line,
    expr2string,
    default_width,
    TERM_THEME,
    highlight_syntax

import ..Renderables: RenderableText
import ..Panels: Panel
import ..Dendograms: Dendogram
import ..Trees: Tree
import ..Layout: hLine
import ..Tprint: tprintln
import ..Repr: termshow

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
            fit = tree.measure.w > default_width(),
            width = max(tree.measure.w, default_width()),
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

# ---------------------------------------------------------------------------- #
#                             INTROSPECT DATATYPES                             #
# ---------------------------------------------------------------------------- #

"""
    inspect(T::DataType; documentation::Bool=false, constructors::Bool=true, methods::Bool=true, supertypes::Bool=true)

Inspect a `DataType` to show info such as docstring, constructors and methods.
Flags can be used to choose the level of detail in the information presented:
 - documentation: show docstring with `termshow`
 - constructors: show `T` constructors
 - methods: show methods using `T` in their signature
 - supertypes: show methods using `T`'s supertypes in their signature
"""
function inspect(
    T::DataType;
    documentation::Bool = false,
    constructors::Bool = true,
    methods::Bool = true,
    supertypes::Bool = true,
)
    hLine("inspecting: $T", style = "bold white") |> print

    documentation && begin
        termshow(T)
        print("\n"^3)
    end

    # types hierarchy
    "{bold white}○ Types hierarchy:" |> tprintln
    "   " * Tree(T) |> print

    # constructors
    constructors && begin
        "\n{bold white}○ {$pink}$T{/$pink} constructors:" |> tprintln
        t_name = split(string(T), '.')[end]
        print.(style_methods(Base.methods(T), t_name))
    end

    # methods with T and supertypes
    methods && begin
        for dt in getsupertypes(T)[1:(end - 1)]
            _methods = methodswith(dt)
            length(_methods) == 0 && continue
            dt_name = split(string(dt), '.')[end]

            "\n{bold white}○ Methods for $dt:" |> tprintln
            print.(style_methods(_methods, dt_name))
            supertypes || break
        end
    end
    nothing
end


function inspect(
    F::Function;
    documentation::Bool = false,
)
    hLine("inspecting: $F", style = "bold white") |> print

    documentation && begin
        termshow(F)
        print("\n"^3)
    end
    nothing
end

end
