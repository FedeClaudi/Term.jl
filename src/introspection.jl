module Introspection

using InteractiveUtils
import InteractiveUtils: supertypes as getsupertypes
import OrderedCollections: OrderedDict
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
    highlight_syntax,
    load_code_and_highlight,
    str_trunc,
    reshape_text

import ..Renderables: RenderableText
import ..Panels: Panel
import ..Dendograms: Dendogram
import ..Trees: Tree
import ..Layout: hLine, vLine, Spacer, rvstack, lvstack
import ..Tprint: tprintln
import ..Repr: termshow
using ..LiveWidgets
import ..LiveWidgets: ArrowDown, ArrowUp, KeyInput
import ..TermMarkdown: parse_md
import ..Consoles: console_width, console_height
import ..Style: apply_style
import ..Compositors: Compositor
import ..Links: Link

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

function style_methods(methods::Union{Vector{Base.Method},Base.MethodList}, docstrings::Vector, width::Int)
    mets = []
    fn_col = TERM_THEME[].func
    panel_col = TERM_THEME[].text_accent
    col = TERM_THEME[].inspect_highlight

    for (i, (m, docs)) in enumerate(zip(methods, docstrings))
        # method code
        code = split(string(m), " in ")[1] |> highlight_syntax
        code = reshape_text(apply_style(code), width - 20; ignore_markup = true)

        # get docstring
        docs = parse_md(something(docs, ""); width=width-20)

        # method source
        modul = "{bold dim $col}" * string(m.module) * "{/bold dim $col}"
        source = "{dim}$(m.file):$(m.line){/dim}"
        push!(mets, docs/""/(modul * " " * code)/""/source)
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
function inspect(T::Union{Union,DataType};)
    # get app size
    layout = :(A(3, 1.0) / B(37, 1.0))
    comp = Compositor(layout)
    widget_width = comp.elements[:B].w - 6
    widget_height = comp.elements[:B].h - 10

    # get fields
    theme = TERM_THEME[]
    field_names = apply_style.(string.(fieldnames(T)), theme.repr_accent)
    field_types = apply_style.(map(f -> "::" * string(f), T.types), theme.repr_type)

    line = vLine(length(field_names); style = theme.repr_name)
    space = Spacer(length(field_names), 1)
    fields = rvstack(field_names...) * space * lvstack(string.(field_types)...)
    type_name = apply_style(string(T), theme.repr_name * " bold")

    # get app content
    type_methods = style_methods(get_methods_with_docstrings(T)..., widget_width - 20)
    methods_pagers = map(
        m -> Pager(string(m); width = widget_width-6, page_lines = widget_height-5),
        type_methods
    ) |> collect


    # create app
    menu = ButtonsMenu(
        ["Info", "Methods"];
        width = comp.elements[:A].w,
        height = comp.elements[:A].h - 1,
        layout = :horizontal,
    )

    gallery_widgets = [
        Pager(
            string(
                Panel(
                    type_name / ("  " * line * fields);
                    fit = false,
                    width = widget_width - 10,
                    justify = :center,
                    title = "Fields",
                    title_style = "bright_blue bold",
                    style = "bright_blue dim",
                ) / hLine(widget_width - 10; style = "dim") / "" / Tree(T),
            );
            width = widget_width,
            page_lines = widget_height,
        ),
        Gallery(
            methods_pagers;
            width = comp.elements[:B].w - 6,
            height = comp.elements[:B].h - 6,
            show_panel = true,
        )
    ]

    widgets = OrderedDict(
        :A => menu,
        :B => Gallery(
            gallery_widgets;
            width = comp.elements[:B].w - 1,
            height = comp.elements[:B].h - 1,
            show_panel = false,
        ),
    )

    transition_rules = OrderedDict{Tuple{Symbol,KeyInput},Symbol}(
    (:A, ArrowDown()) => :B,
    (:B, ArrowUp()) => :A,
    )

    function cb(app)
        app.widgets[:B].active = app.widgets[:A].active
    end

    app = App(layout, widgets, transition_rules; on_draw = cb)
    app.active = :B
    play(app; transient = false)
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
