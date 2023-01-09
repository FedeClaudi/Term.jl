"""
    AbstractWidgetContainer

AbstractWidgetContainer must have two obligatory fields:

    widgets::Vector{AbstractWidget}
    active::Int
"""
abstract type AbstractWidgetContainer <: AbstractWidget end

get_active(container::AbstractWidgetContainer) = container.widgets[container.active]

set_active(container::AbstractWidgetContainer, active) = container.active = active

activate_next_widget(widget::AbstractWidget, ::Any) = widget.active = min(widget.active + 1, length(widget.widgets))

activate_prev_widget(widget::AbstractWidget, ::Any) = widget.active = max(widget.active - 1, 1)
