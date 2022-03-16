using Highlights.Tokens, Highlights.Themes

import MyterialColors: green,
                green_light,
                purple_light,
                blue,
                red,
                green_light,
                blue_light,
                orange_light,
                pink_light,
                orange,
                yellow,
                yellow_light,
                white,
                green

import Parameters: @with_kw

"""
    Theme

Stores colors for different semantically relevant items, used to 
style outputs to terminal.
"""
@with_kw struct Theme
    docstring::String           = green
    string::String              = green_light
    type::String                = purple_light
    emphasis::String            = "$blue  bold"
    emphasis_light::String      = green_light
    code::String                = blue_light
    multiline_code::String      = blue_light
    symbol::String              = orange_light
    expression::String          = pink_light
    number::String              = blue
    operator::String            = "$red bold"
    func::String                = yellow

    # loggin levels
    info::String                = blue
    debug::String               = blue
    warn::String                = orange
    error::String               = "bold $red"

    # Tree objects
    tree_title_style::String    = "$orange italic"
    tree_node_style::String     = "$yellow italic"
    tree_leaf_style::String     = yellow_light
    tree_guide_style::String    = blue
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
