
"""
An `App` is a collection of widgets.
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

    transition_rules = isnothing(transition_rules) ? DIct{Tuple{Symbol, KeyInput}, Symbol}() : transition_rules
    return App(LiveInternals(), measure, compositor, widgets, transition_rules, widgets_keys[1])
end

function frame(app::App; kwargs...)
    for (name, widget) in pairs(app.widgets)
        content = frame(widget)
        background = app.active == name ? "red" : "default"
        content = apply_style(content, "on_$background")

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
- {bold white}enter, esc{/bold white}: quit program, possibly returning a value

- {bold white}q{/bold white}: quit program without returning anything

- {bold white}h{/bold white}: toggle help message display

- {bold white}w{/bold white}: toggle help message display for currently active widget
"""
function key_press(app::App, ::Enter) 
    app.internals.should_stop = true
    return nothing
end

function key_press(app::App, ::Esc) 
    app.internals.should_stop = true
    return nothing
end



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