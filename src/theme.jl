import Parameters: @with_kw

"""
    Theme

Stores colors for different semantically relevant items, used to 
style outputs to terminal.
"""
@with_kw struct Theme
    docstring::AbstractString = "(200, 255, 200)"
    type::AbstractString = "(240, 150, 255)"
    emphasis::AbstractString = "blue  bold"
    emphasis_light::AbstractString = " #96cbfa "
end

theme = Theme()  # default theme