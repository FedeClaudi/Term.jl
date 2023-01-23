"""
    AbstractWidgetContainer

`AbstractWidgetContainer` contain multiple other widgets
and can coordinate their activity. 
AbstractWidgetContainer must have two obligatory fields on top of AbstractWidget's fields:
    widgets::Vector{AbstractWidget}
    active::Int
"""
abstract type AbstractWidgetContainer <: AbstractWidget end

"""
Set the parent of all widgets in `container` to `container`.
"""
set_as_parent(container::AbstractWidgetContainer) = map(
    w -> w.internals.parent = container,
    (container.widgets isa AbstractDict ? values(container.widgets) : container.widgets),
)

"""
Return the active widget in `container`.
"""
get_active(container::AbstractWidgetContainer) = container.widgets[container.active]

"""
Set the active widget in `container` to `active`.
"""
set_active(container::AbstractWidgetContainer, active) = container.active = active

"""
Set the active widget in `container` to the next widget.
"""
function activate_next_widget(widget::AbstractWidget, ::Any)
    widget.active = min(widget.active + 1, length(widget.widgets))
    return :stop
end

"""
Set the active widget in `container` to the previous widget.
"""
function activate_prev_widget(widget::AbstractWidget, ::Any)
    widget.active = max(widget.active - 1, 1)
    return :stop
end
