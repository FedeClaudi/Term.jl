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