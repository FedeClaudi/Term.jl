using Highlights.Tokens, Highlights.Themes

import MyterialColors:
    green,
    green_light,
    purple_light,
    blue,
    red,
    green_light,
    green,
    blue_light,
    orange_light,
    pink_light,
    orange,
    yellow,
    yellow_light,
    white,
    green,
    amber,
    green_dark,
    orange,
    pink,
    blue_grey_light,
    blue_grey_light,
    teal,
    salmon_light,
    indigo_light,
    light_blue,
    cyan_light,
    cyan_lighter

import Parameters: @with_kw

"""
    Theme

Stores colors for different semantically relevant items, used to 
style outputs to terminal.
"""
@with_kw mutable struct Theme
    name::String                        = "default"
    
    # syntax
    docstring::String                   = green_dark
    string::String                      = "#64b565"
    type::String                        = purple_light
    code::String                        = "$yellow"
    multiline_code::String              = "$yellow"
    symbol::String                      = orange
    expression::String                  = amber
    number::String                      = blue_light
    operator::String                    = red
    func::String                        = yellow

    # misc
    text::String                        = "default"
    text_accent::String                 = "white"
    emphasis::String                    = "$blue  bold"
    emphasis_light::String              = yellow_light

    # logging 
    info::String                        = "#7cb0cf"
    debug::String                       = "#197fbd"
    warn::String                        = orange
    error::String                       = "bold #d13f3f"
    logmsg::String                      = "#8abeff"

    # tree 
    tree_title::String                  = "$orange italic"
    tree_node::String                   = "$yellow italic"
    tree_leaf::String                   = yellow_light
    tree_guide::String                  = blue
    tree_max_width::Int                 = 44

    # repr
    repr_accent::String                 = "bold #e0db79"
    repr_name::String                   = "#e3ac8d"
    repr_type::String                   = "#bb86db"
    repr_values::String                 = "#b3d4ff"
    repr_line::String                   = "dim #7e9dd9"
    repr_panel::String                  = "#9bb3e0"

    # errors
    err_accent::String                  = pink
    er_bt::String                       = "#ff8a4f"
    err_btframe_panel::String           = "#9bb3e0"
    err_filepath::String                = "grey62"
    err_errmsg                          = "red"

    # introspection
    inspect_highlight::String           = pink_light
    inspect_accent::String              = pink

    # progress
    progress_accent::String                 = pink
    progress_elapsedcol_default::String     = purple_light
    progress_etacol_default::String         = teal
    progress_spiner_default::String         = "bold blue"
    progress_spinnerdone_default::String    = "green bold"

    # dendogram
    dendo_title                         = salmon_light
    dendo_pretitle::String              = blue_grey_light                  
    dendo_leaves::String                = blue_grey_light
    dendo_lines::String                 = "$blue_light dim bold"

    # markdown
    md_h1::String                       = "bold $indigo_light"
    md_h2::String                       = "bold $blue underline"
    md_h3::String                       = "bold $blue"
    md_h4::String                       = "bold $light_blue"
    md_h5::String                       = "bold $cyan_light"
    md_h6::String                       = "bold $cyan_lighter"
    md_latex::String                    = "$yellow_light italic"
    md_code::String                     = "$yellow_light italic"
    md_codeblock_bg::String             = "#262626"
    md_quote::String                    = "#5a74f2"
    md_footnote::String                 = "#9aacdb"
    md_table_header::String             = "bold yellow"
    md_admonition_note::String          = "blue"
    md_admonition_info::String          = "blue"
    md_admonition_warning::String       = yellow_light
    md_admonition_danger::String        = "red"
    md_admonition_tip::String           = "green"

    # table
    tb_style::String                    = "#9bb3e0"
    tb_header::String                   = "bold white"
    tb_columns::String                  = "defualt"
    tb_footer::String                   = "default"
    tb_box::Symbol                      = :MINIMAL_HEAVY_HEAD
end

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
