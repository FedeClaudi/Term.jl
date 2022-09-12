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
using ..LiveDisplays
import ..TermMarkdown: parse_md
import ..Consoles: console_width

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

function style_methods(
    methods::Union{Vector{Base.Method},Base.MethodList},
    tohighlight::AbstractString,
)
    mets = []
    prevmod = ""
    for (i, m) in enumerate(methods)
        _name = split(string(m), " in ")[1]
        code = (occursin(_name, string(m.name)) ? split(_name, string(m.name))[2] : _name) 

        # code = "{dim}" * code * "{/dim}"
        # code = replace(
        #     code,
        #     tohighlight => "{$pink_light default}$tohighlight{/$pink_light default}{dim}",
        # )
        # code = RenderableText(
        #     "     {$pink dim}($i){/$pink dim}  {$fn_col}$(m.name){/$fn_col}" * code,
        # )
        # info =
        #     string(m.module) != prevmod ?
        #     RenderableText(
        #         "{bright_blue}   ────── Methods in {$pink underline bold}$(m.module){/$pink underline bold} for {$pink}$tohighlight{/$pink} ──────{/bright_blue}",
        #     ) : nothing
        # prevmod = string(m.module)

        # dest = RenderableText("{dim italic}             → $(m.file):$(m.line){/dim italic}")

        # content = isnothing(info) ? code / dest / "" : info / code / dest / ""

        push!(mets, string(code))
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
    T::DataType;
    documentation::Bool = false,
    constructors::Bool = true,
    methods::Bool = true,
    supertypes::Bool = true,
)
    # hLine("inspecting: $T", style = "bold white") |> print

    # documentation && begin
    #     termshow(T)
    #     print("\n"^3)
    # end


    t_name = split(string(T), '.')[end]
    constructors_content = join(string.(Panel.(
        style_methods(Base.methods(T), t_name);
        fit=false, width=40, padding=(0, 0, 0, 0)
        )
        ), '\n'
    )


    # # methods with T and supertypes
    # methods && begin
    #     for dt in getsupertypes(T)[1:(end - 1)]
    #         _methods = methodswith(dt)
    #         length(_methods) == 0 && continue
    #         dt_name = split(string(dt), '.')[end]

    #         "\n{bold white}○ Methods for $dt:" |> tprintln
    #         print.(style_methods(_methods, dt_name))
    #         supertypes || break
    #     end
    # end
    # nothing

    tv = TabViewer(
        [
            PagerTab("Types hierarchy", string(Tree(T))),
            PagerTab("documentation", parse_md(get_docstring(T)[1])),
            PagerTab("Constructors", constructors_content),
        ]
    )

    while true
        LiveDisplays.update!(tv) || break
    end
    stop!(tv)
    println("done")
end

function inspect(F::Function; documentation::Bool = false)
    hLine("inspecting: $F", style = "bold white") |> print

    documentation && begin
        termshow(F)
        print("\n"^3)
    end
    nothing
end

end
