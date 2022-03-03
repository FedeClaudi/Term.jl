using Highlights.Tokens, Highlights.Themes

import Parameters: @with_kw

"""
    Theme

Stores colors for different semantically relevant items, used to 
style outputs to terminal.
"""
@with_kw struct Theme
    docstring::String = "#c8ffc8"
    type::String = "#d880e7"
    emphasis::String = "blue  bold"
    emphasis_light::String = " #bfe0fd "
    code::String = "#ffd77a"
    multiline_code::String = "#ffd77a"
end

theme = Theme()  # default theme


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
        NAME_OTHER=> S"fg: FFF59D; bold",

        # red
        KEYWORD => S"fg: fc6262; bold",
        OPERATOR => S"fg: fc6262; bold",
        PUNCTUATION => S"fg: fc7474",

        # green
        STRING  => S"fg: A5D6A7",
        COMMENT => S"fg: C5E1A5; italic",
        STRING_DOC => S"fg: D4E157",

        # blue
        NUMBER => S"fg: 5dc7fc"
    ),
)