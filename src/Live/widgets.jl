"""
Collection of small widgets
"""

# ---------------------------------------------------------------------------- #
#                                  TEXT WIDGET                                 #
# ---------------------------------------------------------------------------- #

"""
TextWidget just shows a piece of text.
"""
@with_repr mutable struct TextWidget <: AbstractWidget
    internals::LiveInternals
    measure::Measure
    text::String
end

TextWidget(; width=console_width(), height=5) = TextWidget(LiveInternals(), Measure(height, width), "")

TextWidget(text::String; width=console_width(), height=Measure(text).h) = TextWidget(LiveInternals(), Measure(height, width), text)

function frame(tw::TextWidget; kwargs...)
    txt = reshape_text(tw.text, tw.measure.w)
    tw.text = txt
    
    lines = split(txt, "\n")
    lines = lines[1:min(tw.measure.h, length(lines))]

    return RenderableText(join(lines, "\n"))
end


# ---------------------------------------------------------------------------- #
#                                   INPUT BOX                                  #
# ---------------------------------------------------------------------------- #

"""
InputBox collects and displays user input as text. 
"""
@with_repr mutable struct InputBox <: AbstractWidget
    internals::LiveInternals
    measure::Measure
    input_text::Union{Nothing, String}
    blinker_update::Int
    blinker_status::Symbol
end

function InputBox(; height=20, width=console_width()) 
    InputBox(LiveInternals(), Measure(height, width), nothing, 0, :off)
end

function frame(ib::InputBox; kwargs...)
    # create blinking symbol
    currtime = Dates.value(now())
    if currtime - ib.blinker_update > 400
        ib.blinker_update = currtime
        ib.blinker_status = ib.blinker_status == :on ? :off : :on
    end
    blinker = ib.blinker_status == :on ? " " : "{on_white} {/on_white}"

    text = isnothing(ib.input_text) ? "{dim}start typing...{/dim}" : ib.input_text * blinker


    return Panel(
        text;
        width=ib.measure.w-7,
        height=ib.measure.h,
    )
end

"""
- {bold white}enter{/bold white}: new line
"""
function key_press(ib::InputBox, ::Enter)
    isnothing(ib.input_text) && return
    ib.input_text *= "\n"
end

function key_press(ib::InputBox, ::SpaceBar)
    ib.input_text *= " "
end


"""
- {bold white}del{/bold white}: delete a character
"""
function key_press(ib::InputBox, ::Del)
    isnothing(ib.input_text) && return
    textwidth(ib.input_text) > 0 && (ib.input_text = ib.input_text[1:end-1])
end


"""
- {bold white}any character{/bold white}: pressing on any letter character will register this as input
"""
function key_press(ib::InputBox, c::Char)::Tuple{Bool, Nothing}
    if isnothing(ib.input_text)
        ib.input_text = string(c)
    else
        ib.input_text *= c
    end
    return (false, nothing)
end


# ---------------------------------------------------------------------------- #
#                                    BUTTON                                    #
# ---------------------------------------------------------------------------- #

"""
A button. 
"""
@with_repr mutable struct Button <: AbstractWidget
    internals::LiveInternals
    measure::Measure
    pressed_display::Panel
    not_pressed_display::Panel
    status::Symbol
    callback::Union{Nothing, Function}
end


function Button(
    message::String;
    pressed_text_style = "bold white",
    pressed_background = "red",
    not_pressed_text_style = "red",
    width::Int=10,
    height::Int=3,
    kwargs...
)
    pressed = Panel(
        "{$pressed_text_style on_$pressed_background}" * message * "{/$pressed_text_style on_$pressed_background}";
        style=pressed_text_style * " on_$pressed_background",
        width=width, height=height,
        background=pressed_background,
        kwargs...
    )

    not_pressed = Panel(
        "{$not_pressed_text_style}" * message * "{/$not_pressed_text_style}";
        style=not_pressed_text_style,
        width=width, height=height,
        kwargs...
    )

    return Button(
        LiveInternals(), Measure(height, width), pressed, not_pressed, :not_pressed, nothing
    )
end


function frame(b::Button; kwargs...)
    return if b.status == :pressed
        b.pressed_display
    else
        b.not_pressed_display
    end
end

function key_press(b::Button, ::Enter) 
    if b.status == :not_pressed 
        b.status = :pressed
    else
        b.status = :not_pressed
        isnothing(b.callback) || return b.callback(b)
    end
    return nothing
end