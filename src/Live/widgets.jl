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
    as_panel::Bool
end

TextWidget(; width=console_width(), height=5, as_panel=true) = TextWidget(LiveInternals(), Measure(height, width), "", as_panel)

TextWidget(text::String; width=console_width(), height=Measure(text).h, as_panel=true) = TextWidget(LiveInternals(), Measure(height, width), text, as_panel)

function frame(tw::TextWidget; kwargs...)
    tw.as_panel && return Panel(
        tw.text, width=tw.measure.w, height=tw.measure.h+1, fit=false, style="dim"
    )
    
    text = reshape_text(tw.text, tw.measure.w-4)
    
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

    # get text to display
    text = isnothing(ib.input_text) ? "{dim}start typing...{/dim}" : ib.input_text * blinker

    return Panel(
        text;
        width=ib.measure.w,
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

