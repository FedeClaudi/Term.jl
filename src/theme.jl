import Parameters: @with_kw

"""
    Theme

Stores colors for different semantically relevant items, used to 
style outputs to terminal.
"""
@with_kw struct Theme
    docstring::AbstractString = "#c8ffc8"
    type::AbstractString = "#d880e7"
    emphasis::AbstractString = "blue  bold"
    emphasis_light::AbstractString = " #bfe0fd "
end

theme = Theme()  # default theme