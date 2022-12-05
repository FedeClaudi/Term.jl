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
import ..Layout: hLine, vLine, Spacer, rvstack, lvstack
import ..Tprint: tprintln
import ..Repr: termshow
using ..LiveDisplays
import ..TermMarkdown: parse_md
import ..Consoles: console_width
import ..Style: apply_style

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
        style = "$(TERM_THEME[].emphasis) dim",
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
            title_style = "$(TERM_THEME[].emphasis_light) default bold",
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
            title_style = "$(TERM_THEME[].emphasis_light) default bold",
            title_justify = :center,
            style = TERM_THEME[].emphasis,
            fit = true,
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

function style_methods(methods::Union{Vector{Base.Method},Base.MethodList})
    mets = []
    for (i, m) in enumerate(methods)
        _name = split(string(m), " in ")[1]
        code = (occursin(_name, string(m.name)) ? split(_name, string(m.name))[2] : _name) 

        code = replace(
            code,
            string(m.name) => "",
        )
        code = RenderableText(
            "     {$pink dim}($i){/$pink dim}  {$fn_col}$(m.name){/$fn_col}" * code,
        )
        
        dest = RenderableText("{dim italic} $(m.file):$(m.line){/dim italic}")
        push!(mets, string(code/dest))
    end
    return mets
end


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
    T::Union{Union,DataType};
    documentation::Bool = true,
    constructors::Bool = true,
    methods::Bool = false,
    supertypes::Bool = false,
)
    theme = TERM_THEME[]
    hLine("inspecting: $T", style = theme.text_accent) |> print

    documentation || termshow(T; showdocs = false)
    documentation && begin
        termshow(T)
    end
    print("\n"^3)

    # types hierarchy
    "{$(theme.text_accent)}○ Types hierarchy:" |> tprintln
    "   " * Tree(T) |> print

    # constructors
    constructors && begin
        "\n{$(theme.text_accent)}○ {$(theme.inspect_accent)}$T{/$(theme.inspect_accent)} constructors:" |>
        tprintln
        t_name = split(string(T), '.')[end]
        print.(style_methods(Base.methods(T), t_name; constructor = true))
    end

    # methods with T and supertypes
    methods && begin
        for dt in getsupertypes(T)[1:(end - 1)]
            _methods = methodswith(dt)
            length(_methods) == 0 && continue
            dt_name = split(string(dt), '.')[end]

            "\n{$(theme.text_accent)}○ Methods for {$(theme.inspect_accent)}$dt{/$(theme.inspect_accent)}:" |>
            tprintln
            print.(style_methods(_methods, dt_name))
            supertypes || break
        end
    end
    nothing
end

function inspect(F::Function; documentation::Bool = true)
    hLine("inspecting: $F", style = "$(TERM_THEME[].text_accent)") |> print

    documentation && begin
        termshow(F)
        print("\n"^3)
    end
    nothing
end

end
