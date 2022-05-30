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
    orange

import Parameters: @with_kw

"""
    Theme

Stores colors for different semantically relevant items, used to 
style outputs to terminal.
"""
@with_kw mutable struct Theme
    name::String = "default"
    docstring::String = green_dark
    string::String = "#64b565"
    type::String = purple_light
    emphasis::String = "$blue  bold"
    emphasis_light::String = yellow_light
    code::String = "$(yellow) italic"
    multiline_code::String = "$(yellow) italic"
    symbol::String = orange
    expression::String = amber
    number::String = blue_light
    operator::String = "$red"
    func::String = yellow

    # loggin levels
    info::String = "#7cb0cf"
    debug::String = "#197fbd"
    warn::String = orange
    error::String = "bold #d13f3f"

    # Tree objects
    tree_title_style::String = "$orange italic"
    tree_node_style::String = "$yellow italic"
    tree_leaf_style::String = yellow_light
    tree_guide_style::String = blue
    tree_max_width::Int = 44

    # Repr
    repr_accent_style = "bold #e0db79"
    repr_name_style = "#e3ac8d"
    repr_type_style = "#bb86db"
    repr_values_style = "#b3d4ff"
    repr_line_style = "dim #7e9dd9"
    repr_panel_style = "#9bb3e0"
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

    content =
        hLine(30, "Base"; style = "#9bb3e0") /
        (rvstack(values[2:13]) * Spacer(2, 1) * lvstack(fields[2:13]))
    content /= "" / hLine(30, "Logging"; style = "#9bb3e0")
    content /= (rvstack(values[14:17]) * Spacer(2, 1) * lvstack(fields[14:17]))
    content /= "" / hLine(30, "Tree"; style = "#9bb3e0")
    content /= (rvstack(values[18:22]) * Spacer(2, 1) * lvstack(fields[18:22]))
    content /= "" / hLine(30, "REPL"; style = "#9bb3e0")
    content /= (rvstack(values[23:end]) * Spacer(2, 1) * lvstack(fields[23:end]))

    return print(
        io,
        Panel(
            content;
            width = 44,
            justify = :center,
            title = "Theme: {bold}$(theme.name){/bold}",
            padding = (4, 4, 1, 1),
            style = "#9bb3e0",
            title_style = "white",
        ),
    )
end

set_theme(theme::Theme) = (term_theme[] = theme)

# ------------------------------ Highlighters.jl ----------------------------- #

"""
Custom hilighting theme for Highlighters.jl
https://juliadocs.github.io/Highlights.jl/stable/man/theme/
"""
abstract type CodeTheme <: AbstractTheme end

@theme CodeTheme Dict(
    :style => S"",
    :tokens => Dict(
        # TEXT    => S"fg: e6e8e6",
        # yellow
        NAME_FUNCTION => S"fg: FFF59D; bold",
        NAME_OTHER => S"fg: FFF59D; bold",

        # red
        KEYWORD => S"fg: fc6262; bold",
        OPERATOR => S"fg: fc6262; bold",
        PUNCTUATION => S"fg: fc7474",

        # green
        STRING => S"fg: A5D6A7",
        COMMENT => S"fg: C5E1A5; italic",
        STRING_DOC => S"fg: D4E157",

        # blue
        NUMBER => S"fg: 90CAF9",
    ),
)
