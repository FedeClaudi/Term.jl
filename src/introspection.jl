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
    fn_col = TERM_THEME[].func
    for (i, m) in enumerate(methods)
        _name = split(string(m), " in ")[1]
        code = (occursin(_name, string(m.name)) ? split(_name, string(m.name))[2] : _name)

        code = replace(code, string(m.name) => "")
        code = RenderableText(
            "     {$pink dim}($i){/$pink dim}  {$(fn_col)}$(m.name){/$(fn_col)}" * code,
        )

        dest = RenderableText("{dim italic} $(m.file):$(m.line){/dim italic}")
        push!(mets, string(code / dest))
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
)
    constructors_content = join(
        string.(
            Panel.(
                style_methods(Base.methods(T));
                fit=false, width=console_width()-33, padding=(0, 0, 0, 0),
                style="hidden"
            )
        ), '\n'
    )

    _methods = vcat(methodswith.(getsupertypes(T)[1:3])...)
    supertypes_methods = join(
        string.(
                Panel.(
                style_methods(_methods);
                fit=false, width=console_width()-33, padding=(0, 0, 0, 0),
                style="hidden"
            )
        ),
    "\n")

    theme = TERM_THEME[]
    field_names = apply_style.(string.(fieldnames(T)), theme.repr_accent)
    field_types = apply_style.(map(f -> "::" * string(f), T.types), theme.repr_type)

    line = vLine(length(field_names); style = theme.repr_name)
    space = Spacer(length(field_names), 1)
    fields = rvstack(field_names...) * space * lvstack(string.(field_types)...)
    type_name = apply_style(string(T), theme.repr_name * " bold")


    tv = TabViewer(
        [
            PagerTab("Info", 
                string(
                Panel(type_name / ("  " * line * fields); fit=false, 
                        width=console_width()-33, justify=:center,
                        title="Fields", title_style="bright_blue bold",
                        style="bright_blue dim"
                ) /
                hLine(console_width()-33; style="dim") / 
                "" /
                Tree(T))
            
            ),
            PagerTab("documentation", parse_md(get_docstring(T)[1]; width=console_width()-33)),
            PagerTab("Constructors", constructors_content),
            PagerTab("Methods", supertypes_methods),
        ]
    )


    LiveDisplays.play(tv) 

    stop!(tv)
    println("done")
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
