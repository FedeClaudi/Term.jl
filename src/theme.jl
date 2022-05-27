using Highlights.Tokens, Highlights.Themes

import MyterialColors: green,
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
    docstring::String           = green_dark
    string::String              = "#64b565"
    type::String                = purple_light
    emphasis::String            = "$blue  bold"
    emphasis_light::String      = yellow_light
    code::String                = "$(yellow) italic"
    multiline_code::String      = "$(yellow) italic"
    symbol::String              = orange
    expression::String          = amber
    number::String              = blue_light
    operator::String            = "$red"
    func::String                = yellow

    # loggin levels
    info::String                = "#7cb0cf"
    debug::String               = "#197fbd"
    warn::String                = "#d1923f"
    error::String               = "bold #d13f3f"

    # Tree objects
    tree_title_style::String    = "$orange italic"
    tree_node_style::String     = "$yellow italic"
    tree_leaf_style::String     = yellow_light
    tree_guide_style::String    = blue
    tree_max_width::Int         = 44
end

theme = Theme() # default theme

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
