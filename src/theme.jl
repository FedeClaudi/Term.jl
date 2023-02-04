using Highlights.Tokens, Highlights.Themes
import Markdown: @md_str
using MyterialColors

import Parameters: @with_kw

"""
    Theme

Stores colors for different semantically relevant items, used to 
style outputs to terminal.
"""
@with_kw mutable struct Theme
    name::String = "default"

    # syntax
    docstring::String      = green_dark
    string::String         = "#64b565"
    type::String           = purple_light
    code::String           = yellow
    multiline_code::String = yellow
    symbol::String         = orange
    expression::String     = amber
    number::String         = blue_light
    operator::String       = red
    func::String           = "#f2d777"
    link::String           = "underline $(light_blue_light)"

    # misc
    text::String           = "default"
    text_accent::String    = "white"
    emphasis::String       = "$blue  bold"
    emphasis_light::String = yellow_light
    line::String           = "default" # used by Panel,  hLine, vLine
    box::Symbol            = :ROUNDED  # used by Panel,  hLine, vLine

    # logging 
    info::String   = "#7cb0cf"
    debug::String  = "#197fbd"
    warn::String   = orange
    error::String  = "bold #d13f3f"
    logmsg::String = "#8abeff"

    # tree 
    tree_mid::String         = blue
    tree_terminator::String  = blue
    tree_skip::String        = blue
    tree_dash::String        = blue
    tree_trunc::String       = blue
    tree_pair::String        = red_light
    tree_keys::String        = yellow
    tree_title::String       = "bold " * orange
    tree_max_leaf_width::Int = 44

    # repr
    repr_accent::String      = "bold #e0db79"
    repr_name::String        = "#e3ac8d"
    repr_type::String        = "#bb86db"
    repr_values::String      = "#b3d4ff"
    repr_line::String        = "dim #7e9dd9"
    repr_panel::String       = "#9bb3e0"
    repr_array_panel::String = "dim yellow"
    repr_array_title::String = "dim bright_blue"
    repr_array_text::String  = "bright_blue"

    # errors
    err_accent::String        = pink
    er_bt::String             = "#ff8a4f"
    err_btframe_panel::String = "#9bb3e0"
    err_filepath::String      = "grey62"
    err_errmsg                = "red"

    # introspection
    inspect_highlight::String = pink_light
    inspect_accent::String    = pink

    # progress
    progress_accent::String              = pink
    progress_elapsedcol_default::String  = purple_light
    progress_etacol_default::String      = teal
    progress_spiner_default::String      = "bold blue"
    progress_spinnerdone_default::String = "green bold"

    # dendogram
    dendo_title            = salmon_light
    dendo_pretitle::String = blue_grey_light
    dendo_leaves::String   = blue_grey_light
    dendo_lines::String    = "$blue_light dim bold"

    # markdown
    md_h1::String                 = "bold $indigo_light"
    md_h2::String                 = "bold $blue underline"
    md_h3::String                 = "bold $blue"
    md_h4::String                 = "bold $light_blue"
    md_h5::String                 = "bold $cyan_light"
    md_h6::String                 = "bold $cyan_lighter"
    md_latex::String              = "$yellow_light italic"
    md_code::String               = "$yellow_light italic"
    md_codeblock_bg::String       = "#202020"
    md_quote::String              = "#5a74f2"
    md_footnote::String           = "#9aacdb"
    md_table_header::String       = "bold yellow"
    md_admonition_note::String    = "blue"
    md_admonition_info::String    = "blue"
    md_admonition_warning::String = yellow_light
    md_admonition_danger::String  = "red"
    md_admonition_tip::String     = "green"

    # table
    tb_style::String   = "#9bb3e0"
    tb_header::String  = "bold white"
    tb_columns::String = "default"
    tb_footer::String  = "default"
    tb_box::Symbol     = :MINIMAL_HEAVY_HEAD

    # prompt
    prompt_text::String           = blue
    prompt_default_option::String = "underline bold $green"
    prompt_options::String        = "default"

    # annotations
    annotation_color::String = blue_light
end

(t::Theme)(::Function) = t.func
(t::Theme)(::Number) = t.number
(t::Theme)(::Union{UnionAll,DataType}) = t.type
(t::Theme)(::Symbol) = t.symbol
(t::Theme)(::Expr) = t.expression
(t::Theme)(::AbstractVector) = t.number
(t::Theme)(::Any) = t.text

# ---------------------------------- themes ---------------------------------- #
DarkTheme = Theme(name = "dark")

LightTheme = Theme(
    name = "light",

    # syntax
    docstring      = green_dark,
    string         = "#64b565",
    type           = purple_dark,
    code           = yellow_darker,
    multiline_code = yellow_darker,
    symbol         = orange,
    expression     = amber,
    number         = blue_dark,
    operator       = red,
    func           = yellow_darker,

    # misc
    text           = "default",
    text_accent    = grey_dark,
    emphasis       = "$blue  bold",
    emphasis_light = yellow_dark,
    line           = "default",

    # logging 
    info   = "#7cb0cf",
    debug  = "#197fbd",
    warn   = orange,
    error  = "bold #d13f3f",
    logmsg = "#8abeff",

    # tree 
    tree_mid = blue_darker,
    tree_terminator = blue_darker,
    tree_skip = blue_darker,
    tree_dash = blue_darker,
    tree_trunc = blue_darker,
    tree_pair = red_light,
    tree_keys = red_dark,
    tree_max_leaf_width = 44,

    # repr
    repr_accent      = "bold $yellow_darker",
    repr_name        = yellow_darker,
    repr_type        = purple_darker,
    repr_values      = indigo_darker,
    repr_line        = "dim $indigo_dark",
    repr_panel       = "black",
    repr_array_panel = "dim $yellow_darker",
    repr_array_title = "dim $blue_dark",
    repr_array_text  = "$blue_dark",

    # errors
    err_accent        = pink_darker,
    er_bt             = "#ff8a4f",
    err_btframe_panel = "#9bb3e0",
    err_filepath      = "grey62",
    err_errmsg        = "red",

    # introspection
    inspect_highlight = pink_dark,
    inspect_accent    = pink,

    # progress
    progress_accent              = pink_darker,
    progress_elapsedcol_default  = purple_dark,
    progress_etacol_default      = teal_darker,
    progress_spiner_default      = "bold $blue_dark",
    progress_spinnerdone_default = "$green_dark bold",

    # dendogram
    dendo_title    = salmon_dark,
    dendo_pretitle = blue_grey_dark,
    dendo_leaves   = blue_grey_dark,
    dendo_lines    = "$blue_dark dim bold",

    # markdown
    md_h1                 = "bold $indigo_dark",
    md_h2                 = "bold $blue underline",
    md_h3                 = "bold $blue",
    md_h4                 = "bold $indigo_dark",
    md_h5                 = "bold $cyan_dark",
    md_h6                 = "bold $cyan_darker",
    md_latex              = "$yellow_dark italic",
    md_code               = "$yellow_dark italic",
    md_codeblock_bg       = "#262626",
    md_quote              = "#5a74f2",
    md_footnote           = "#9aacdb",
    md_table_header       = "bold yellow",
    md_admonition_note    = "blue",
    md_admonition_info    = "blue",
    md_admonition_warning = yellow_dark,
    md_admonition_danger  = "red",
    md_admonition_tip     = "green",

    # table
    tb_style   = grey_darker,
    tb_header  = "bold black",
    tb_columns = "black",
    tb_footer  = "black",
)

# ---------------------------------- display --------------------------------- #

function Base.show(io::IO, ::MIME"text/plain", theme::Theme)
    fields = fieldnames(Theme)
    N = length(fields)
    values = map(f -> getfield(theme, f), fields)

    fields = map(v -> if v[2] isa String
        RenderableText(string(v[1]); style = v[2])
    else
        RenderableText(string(v[1]))
    end, zip(fields, values))

    values = map(
        v -> v isa String ? RenderableText("■■"; style = v) : RenderableText(string(v)),
        values,
    )

    content = rvstack(values) * Spacer(1, 2) * lvstack(fields)

    return print(
        io,
        Panel(
            content;
            width = 66,
            justify = :center,
            title = "Theme: {bold}$(theme.name){/bold}",
            padding = (4, 4, 1, 1),
            style = "#9bb3e0",
            title_style = "white",
        ),
    )
end

set_theme(theme::Theme) = (TERM_THEME[] = theme)

function demo_theme(theme::Theme = TERM_THEME[])
    # change theme
    currtheme = TERM_THEME[]
    set_theme(theme)

    # ------------------------------- prepare data ------------------------------- #
    markdow_text = md"""
    # Header lvl 1
    ##  Header lvl two
    ###  Header lvl three
    ####  Header lvl four
    #####  Header lvl five
    ######  Header lvl six

    ---
    ### Math
    ```math
    f(a) = \frac{1}{2\pi}\int_{0}^{2\pi} (\alpha+R\cos(\theta))d\theta
    ```
    .

    ### Code

    ```julia
    function say_hi(x)
        print("Hellow World")
    end
    ```

     ### Quotes
     > Multi line quote

      
    ### Admonitions
    !!! note
        note admonition

    !!! warning
        warning admonition

    !!! danger
        danger admonition

    !!! tip
        tip admonition

    ### Tables
    | Term | handles | tables|
    |:---------- | ---------- |:------------:|
    | Row `1`    | Column `2` |              |
    | *Row* 2    | **Row** 2  | Column ``3`` |

    """

    tree_dict = Dict(
        "nested" => Dict("n1" => 1, "n2" => 2),
        "leaf2" => 2,
        "leaf" => 2,
        "leafme" => "v",
        "canopy" => "test",
    )

    t = 1:5
    table_data = hcat(t, ones(length(t)), rand(Int8, length(t)))

    # ---------------------------------- display --------------------------------- #
    hLine("Renderables") |> println
    Panel() |> println

    hLine("logging") |> println
    @info "info logging" √9
    @debug "debug logging"
    @warn "warn logging"
    @error "error logging"

    hLine("Tree") |> println
    Tree(tree_dict) |> println

    hLine("Dendogram") |> println
    Dendogram("awesome", "this", :is, "a", "dendogram!") |> println

    hLine("Table") |> println
    Table(table_data; header = ["Num", "Const.", "Values"]) |> println

    hLine("Term show") |> println
    termshow(collect(t))
    termshow(rand(5, 5))
    termshow(tree_dict)

    # hLine("Markdown") |> println
    # tprintln(markdow_text)

    # reset theme
    set_theme(currtheme)
    nothing
end

# ------------------------------ Highlighters.jl ----------------------------- #

"""
Custom hilighting theme for Highlighters.jl
https://juliadocs.github.io/Highlights.jl/stable/man/theme/
"""
abstract type CodeTheme <: AbstractTheme end

@theme CodeTheme Dict(
    :style => S"",
    :tokens => Dict(
        TEXT => S"fg: dedede;",

        # yellow
        NAME_FUNCTION => S"fg: e8d472;",
        NAME_OTHER => S"fg: e8d472;",

        # red
        KEYWORD => S"fg: 7a93f5;",
        OPERATOR => S"fg: de6d59;",
        PUNCTUATION => S"fg: e38864",

        # green
        STRING => S"fg: 50ad5f",
        COMMENT => S"fg: 287a36; italic",
        STRING_DOC => S"fg: 50ad5f",

        # blue
        NUMBER => S"fg: 90CAF9",
    ),
)
