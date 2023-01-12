# ---------------------------------------------------------------------------- #
#                                AbstractButton                                #
# ---------------------------------------------------------------------------- #
abstract type AbstractButton <: AbstractWidget end


function press_button(b::AbstractButton, ::Union{SpaceBar, Enter})
    if b.status == :not_pressed
        b.lastpressed = Dates.value(now())
        b.status = :pressed
        isnothing(b.callback) || return b.callback(b)
    else
        b.status = :not_pressed
    end
    return nothing
end


button_controls = Dict(
    'q' => quit,
    Esc() => quit,
    Enter() => press_button,
    SpaceBar() => press_button,
)


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
    height,
    width;
    kwargs...,
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


function on_layout_change(b::AbstractButton, m::Measure)
    pressed, not_pressed = make_buttons_panels(b.style_args..., m.h, m.w; b.style_kwargs...)
    
    b.pressed_display = pressed
    b.not_pressed_display = not_pressed
    b.measure = m
end


# ---------------------------------------------------------------------------- #
#                                    Button                                    #
# ---------------------------------------------------------------------------- #
# ------------------------------- constructors ------------------------------- #

@with_repr mutable struct Button <: AbstractButton
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
    pressed_display::Panel
    not_pressed_display::Panel
    status::Symbol
    callback::Union{Nothing,Function}
    lastpressed::Int
    on_draw::Union{Nothing,Function}
    style_args
    style_kwargs
end

function Button(
    message::String;
    controls::AbstractDict = button_controls,
    pressed_text_style = "bold white",
    pressed_background = "red",
    not_pressed_text_style = "red",
    on_draw::Union{Nothing,Function} = nothing,
    kwargs...,
)

    return Button(
        Measure(),
        controls,
        nothing,
        Panel(),  # place holders
        Panel(),
        :not_pressed,
        nothing,
        0,
        on_draw,
        (message, pressed_text_style, pressed_background, not_pressed_text_style),
        kwargs
    )
end



# ----------------------------------- frame ---------------------------------- #
function frame(b::Button; kwargs...)
    isnothing(b.on_draw) || b.on_draw(b)

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
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
    pressed_display::Panel
    not_pressed_display::Panel
    status::Symbol
    callback::Union{Nothing,Function}
    lastpressed::Int
    on_draw::Union{Nothing,Function}
    style_args
    style_kwargs
end

function ToggleButton(
    message::String;
    controls::AbstractDict = button_controls,
    pressed_text_style = "bold white",
    pressed_background = "red",
    not_pressed_text_style = "red",
    on_draw::Union{Nothing,Function} = nothing,
    kwargs...,
)

    return ToggleButton(
        Measure(5, 20),
        controls,
        nothing,
        Panel(),
        Panel(),
        :not_pressed,
        nothing,
        0,
        on_draw,
        (message, pressed_text_style, pressed_background, not_pressed_text_style),
        kwargs
    )
end

# ----------------------------------- frame ---------------------------------- #
function frame(b::ToggleButton; kwargs...)
    isnothing(b.on_draw) || b.on_draw(b)

    return if b.status == :pressed
        b.pressed_display
    else
        b.not_pressed_display
    end
end
