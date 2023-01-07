"""
    AbstractWidgetContainer

AbstractWidgetContainer must have two obligatory fields:

    widgets::Vector{AbstractWidget}
    active::Int
"""
abstract type AbstractWidgetContainer <: AbstractWidget end

get_active(container::AbstractWidgetContainer) = container.widgets[widget.active]

"""
    activate_next(container::AbstractWidgetContainer)
Set next widget as active
"""
function activate_next(container::AbstractWidgetContainer)
    container.active = min(container.active + 1, length(container.widgets))
end

"""
    activate_next(container::AbstractWidgetContainer)

Set next widget as active
"""
function activate_previous(container::AbstractWidgetContainer)
    container.active = max(container.active - 1, 1)
end

# --------------------------------- controls --------------------------------- #

"""
- {bold white}esc{/bold white}: quit program, without returning a value

- {bold white}q{/bold white}: quit program without returning anything

- {bold white}h{/bold white}: toggle help message display

- {bold white}w{/bold white}: toggle help message display for currently active widget
"""
function key_press(container::AbstractWidgetContainer, ::Enter)
    widget = container.widgets[container.active]
    if widget isa InputBox || widget isa AbstractButton
        return key_press(widget, Enter())
    else
        return key_press(container, Esc())
    end
end

function key_press(container::AbstractWidgetContainer, c::Char)::Tuple{Bool,Nothing}
    widget = get_active(container)

    if !isa(widget, InputBox)
        c == 'q' && return (true, nothing)
        c == 'h' && begin
            toggle_help(container)
            return (false, nothing)
        end
        c == 'w' && begin
            toggle_help(container; help_widget = widget)
            return (false, nothing)
        end
    end

    return return key_press(widget, c)
end
