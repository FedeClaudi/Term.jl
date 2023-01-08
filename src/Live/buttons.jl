# ---------------------------------------------------------------------------- #
#                                AbstractButton                                #
# ---------------------------------------------------------------------------- #
abstract type AbstractButton <: AbstractWidget end

"""
- {white bold}space, enter{/white bold}: press button
"""
function key_press(b::AbstractButton, ::Enter)
    if b.status == :not_pressed
        b.lastpressed = Dates.value(now())
        b.status = :pressed
        isnothing(b.callback) || return b.callback(b)
    else
        b.status = :not_pressed
    end
    return nothing
end

key_press(b::AbstractButton, ::SpaceBar) = key_press(b, Enter())

"""
    make_buttons_panels(
        pressed_text_style,
        pressed_background,
        not_pressed_text_style,
        width,
        height,
    )

Create styled `Panel`s to visualize active/inactive buttons
"""
function make_buttons_panels(
    message,
    pressed_text_style,
    pressed_background,
    not_pressed_text_style,
    width,
    height;
    kwargs...
)
    pressed = Panel(
        "{$pressed_text_style on_$pressed_background}" *
        message *
        "{/$pressed_text_style on_$pressed_background}";
        style = pressed_text_style * " on_$pressed_background",
        width = width,
        height = height,
        justify = :center,
        background = pressed_background,
        kwargs...,
    )

    not_pressed = Panel(
        "{$not_pressed_text_style}" * message * "{/$not_pressed_text_style}";
        style = not_pressed_text_style,
        width = width,
        height = height,
        justify = :center,
        kwargs...,
    )

    return pressed, not_pressed
end

# ---------------------------------------------------------------------------- #
#                                    Button                                    #
# ---------------------------------------------------------------------------- #
# ------------------------------- constructors ------------------------------- #

@with_repr mutable struct Button <: AbstractButton
    internals::LiveInternals
    measure::Measure
    pressed_display::Panel
    not_pressed_display::Panel
    status::Symbol
    callback::Union{Nothing,Function}
    lastpressed::Int
end

function Button(
    message::String;
    pressed_text_style = "bold white",
    pressed_background = "red",
    not_pressed_text_style = "red",
    width::Int = 10,
    height::Int = 3,
    kwargs...,
)
    pressed, not_pressed = make_buttons_panels(
        message,
        pressed_text_style,
        pressed_background,
        not_pressed_text_style,
        width,
        height;
        kwargs...
    )

    return Button(
        LiveInternals(),
        Measure(height, width),
        pressed,
        not_pressed,
        :not_pressed,
        nothing,
        0,
    )
end

# ----------------------------------- frame ---------------------------------- #
function frame(b::Button; kwargs...)
    return if b.status == :pressed
        currtime = Dates.value(now())
        if currtime - b.lastpressed > 100
            b.status = :not_pressed
            b.not_pressed_display
        else
            b.pressed_display
        end
    else
        b.not_pressed_display
    end
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
    internals::LiveInternals
    measure::Measure
    pressed_display::Panel
    not_pressed_display::Panel
    status::Symbol
    callback::Union{Nothing,Function}
    lastpressed::Int
end

function ToggleButton(
    message::String;
    pressed_text_style = "bold white",
    pressed_background = "red",
    not_pressed_text_style = "red",
    width::Int = 10,
    height::Int = 3,
    kwargs...,
)
    pressed, not_pressed = make_buttons_panels(
        message,
        pressed_text_style,
        pressed_background,
        not_pressed_text_style,
        width,
        height;
        kwargs...
    )

    return ToggleButton(
        LiveInternals(),
        Measure(height, width),
        pressed,
        not_pressed,
        :not_pressed,
        nothing,
        0,
    )
end

# ----------------------------------- frame ---------------------------------- #
function frame(b::ToggleButton; kwargs...)
    return if b.status == :pressed
        b.pressed_display
    else
        b.not_pressed_display
    end
end