# ---------------------------------------------------------------------------- #
#                                AbstractButton                                #
# ---------------------------------------------------------------------------- #
abstract type AbstractButton <: AbstractWidget end

"""
set the buttoon's state to :presed.
"""
function press_button(b::AbstractButton, ::Union{SpaceBar,Enter})
    if b.status == :not_pressed
        b.lastpressed = Dates.value(now())
        b.status = :pressed
        isnothing(b.callback) || return b.callback(b)
    else
        b.status = :not_pressed
    end
    return nothing
end

button_controls =
    Dict('q' => quit, Esc() => quit, Enter() => press_button, SpaceBar() => press_button)

function on_layout_change(b::AbstractButton, m::Measure)
    b.internals.measure = m
end

"""
    make_button_panel(message, color, text_color, pressed, active, w, h; kwargs...)

Create a panel to display a button.
"""
function make_button_panel(message, color, text_color, pressed, active, w, h; kwargs...)
    if pressed == :active
        style = "$(text_color) on_$(color)"
        background = color
    else
        style = active ? color : "dim $color"
        background = ""
    end

    return Panel(
        "{$text_color on_$(background)}$message{/$text_color on_$(background)}",
        style = style,
        width = w,
        height = h,
        justify = get(kwargs, :justify, :center),
        background = background,
        kwargs...,
    )
end

# ---------------------------------------------------------------------------- #
#                                    Button                                    #
# ---------------------------------------------------------------------------- #
# ------------------------------- constructors ------------------------------- #

"""
    Button

A button widget.
It's display changes when pressed.
A callback can be set to be called when the button is pressed.
"""
@with_repr mutable struct Button <: AbstractButton
    internals::WidgetInternals
    controls::AbstractDict
    message::String
    status::Symbol
    callback::Union{Nothing,Function}
    lastpressed::Int
    color::String
    text_color::String
    kwargs
end

function Button(
    message::String;
    controls::AbstractDict = button_controls,
    text_color = "bold white",
    color = "red",
    on_draw::Union{Nothing,Function} = nothing,
    on_activated::Function = on_activated,
    on_deactivated::Function = on_deactivated,
    kwargs...,
)
    return Button(
        WidgetInternals(Measure(), nothing, on_draw, on_activated, on_deactivated, false),
        controls,
        message,
        :not_pressed,
        nothing,
        0,
        color,
        text_color,
        kwargs,
    )
end

# ----------------------------------- frame ---------------------------------- #
function frame(b::Button; kwargs...)
    isnothing(b.internals.on_draw) || b.internals.on_draw(b)

    status = if b.status == :pressed
        currtime = Dates.value(now())

        if currtime - b.lastpressed > 100
            b.status = :not_pressed
            :inactive
        else
            :active
        end
    else
        :inactive
    end

    return make_button_panel(
        b.message,
        b.color,
        b.text_color,
        status,
        isactive(b),
        b.internals.measure.w,
        b.internals.measure.h;
        kwargs...,
    )
end

# ---------------------------------------------------------------------------- #
#                                 TOGGLE BUTTON                                #
# ---------------------------------------------------------------------------- #
# ------------------------------- constructors ------------------------------- #
"""
A button. Pressing it toggles its status between 
activated and not.
"""
@with_repr mutable struct ToggleButton <: AbstractButton
    internals::WidgetInternals
    controls::AbstractDict
    message::String
    status::Symbol
    callback::Union{Nothing,Function}
    lastpressed::Int
    color::String
    text_color::String
    kwargs
end

function ToggleButton(
    message::String;
    controls::AbstractDict = button_controls,
    text_color = "bold white",
    color = "red",
    on_draw::Union{Nothing,Function} = nothing,
    on_activated::Function = on_activated,
    on_deactivated::Function = on_deactivated,
    kwargs...,
)
    return Button(
        WidgetInternals(Measure(), nothing, on_draw, on_activated, on_deactivated, false),
        controls,
        message,
        :not_pressed,
        nothing,
        0,
        color,
        text_color,
        kwargs,
    )
end

# ----------------------------------- frame ---------------------------------- #
function frame(b::ToggleButton; kwargs...)
    isnothing(b.internals.on_draw) || b.internals.on_draw(b)

    status = if b.status == :pressed
        :active
    else
        :inactive
    end

    return make_button_panel(
        b.message,
        b.color,
        b.text_color,
        status,
        isactive(b),
        b.internals.measure.w,
        b.internals.measure.h;
        kwargs...,
    )
end
