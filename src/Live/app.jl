
"""
An `App` is a collection of widgets.

!!! tip
    Transition rules bind keys to "movement" in the app to change
    focus to a different widget
"""
@with_repr mutable struct App <: AbstractWidget
    internals::LiveInternals
    measure::Measure
    compositor::Compositor
    widgets::Dict{Symbol, AbstractWidget}
    transition_rules::Dict{Tuple{Symbol, KeyInput}, Symbol}
    active::Symbol
end

function App(
    layout::Expr,
    widgets::Dict,
    transition_rules::Union{Nothing, Dict{Tuple{Symbol, KeyInput}, Symbol}},
)

    # parse the layout expression and get the compositor
    compositor = Compositor(layout)
    measure = render(compositor).measure

    # check that the layout and the widgets match
    layout_keys = compositor.elements |> keys |> collect
    widgets_keys = widgets |> keys |> collect
    @assert layout_keys == widgets_keys "Mismatch between widget names and layout names"

    # check that the widgets have the right size
    for k in layout_keys
        elem, widget = compositor.elements[k], widgets[k]
        @assert widget.measure.w <= elem.w "Widget $(k) has width $(widget.measure.w) but should have $(elem.w) to fit in layout"
        @assert widget.measure.h <= elem.h-1 "Widget $(k) has height $(widget.measure.h) but should have $(elem.h-1) to fit in layout"

        widget.measure.w < elem.w && @warn "Widget $(k) has width $(widget.measure.w) but should have $(elem.w) to fit in layout"
        widget.measure.h < elem.h-1 && @warn "Widget $(k) has height $(widget.measure.h) but should have $(elem.h-1) to fit in layout"
    end


    transition_rules = isnothing(transition_rules) ? Dict{Tuple{Symbol, KeyInput}, Symbol}() : transition_rules

    # make an error message to show transition rules
    color = TERM_THEME[].emphasis_light
    transition_rules_message = []
    for ((at, key), v) in pairs(transition_rules)
        push!(
            transition_rules_message, 
            "{$color}$key {/$color} moves from {$(color)}$at {/$color} to {$color}$v {/$color}"
        )
    end

    msg_style = TERM_THEME[].emphasis
    return App(LiveInternals(; help_message="\n{$msg_style}Transition rules{/$msg_style}"/join(transition_rules_message, "\n")), measure, compositor, widgets, transition_rules, widgets_keys[1])
end

function frame(app::App; kwargs...)
    for (name, widget) in pairs(app.widgets)
        content = frame(widget)
        content = app.active == name ? hLine(content.measure.w)/content : "" / content
        update!(app.compositor, name, content)
    end
    return render(app.compositor)
end


function key_press(app::App, key::KeyInput)
    # see if a rule has been implemented
    app.active = try
        app.transition_rules[(app.active, key)]
    catch
        key_press(app.widgets[app.active], key)  # pass action to widget
        app.active
    end
end

"""
- {bold white}esc{/bold white}: quit program, without returning a value

- {bold white}q{/bold white}: quit program without returning anything

- {bold white}h{/bold white}: toggle help message display

- {bold white}w{/bold white}: toggle help message display for currently active widget
"""
function key_press(app::App, ::Enter) 
    widget = app.widgets[app.active]
    if widget isa InputBox || widget isa AbstractButton
        return key_press(widget, Enter())
    else
        return key_press(app, Esc())
    end
end

function key_press(app::App, ::Esc) 
    app.internals.should_stop = true
    return nothing
end


"""
-  all other keys are passed to the currently active widget.
"""
function key_press(app::App, c::Char)::Tuple{Bool, Nothing}
    widget = app.widgets[app.active]

    if !isa(widget, InputBox)
        c == 'q' && return (true, nothing)
        c == 'h' && begin
        toggle_help(app)
            return (false, nothing)
        end
        c == 'w' && begin
            toggle_help(app; help_widget=widget)
            return (false, nothing)
        end
    end

    return return key_press(widget, c)
end