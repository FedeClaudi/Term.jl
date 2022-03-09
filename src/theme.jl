using Highlights.Tokens, Highlights.Themes

import Parameters: @with_kw

"""
    Theme

Stores colors for different semantically relevant items, used to 
style outputs to terminal.
"""
@with_kw struct Theme
    docstring::String = "#a7de97"  # green
    string::String = "#A5D6A7"  # green
    type::String = "#d880e7"  # purple
    emphasis::String = "blue  bold"
    emphasis_light::String = "#bfe0fd"  # pale green
    code::String = "#ffd77a"  # light blue
    multiline_code::String = "#ffd77a"  # light blue
    symbol::String = "#ffc94d"  # orange light
    expression::String = "#F48FB1"  # pink light
    number::String = "#90CAF9"  # blue
    operator::String = "#fc6262 bold" # red
    func::String = "#fff126" # yellow

    # loggin levels
    info::String = "#90CAF9"  # blue
    debug::String = "#90CAF9"  # blue
    warn::String = "#ff681c"  # orange
    error::String = "bold red"  # orange
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
