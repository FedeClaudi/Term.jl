"""
Collection of small widgets
"""

# ---------------------------------------------------------------------------- #
#                                  TEXT WIDGET                                 #
# ---------------------------------------------------------------------------- #

# ------------------------------- constructors ------------------------------- #
"""
TextWidget just shows a piece of text.
"""
@with_repr mutable struct TextWidget <: AbstractWidget
    internals::LiveInternals
    measure::Measure
    controls::AbstractDict
    text::String
    as_panel::Bool
    on_draw::Union{Nothing,Function}
end

text_widget_controls = Dict(
    'q' => quit,
    Esc() => quit,
)

TextWidget(;
    width = console_width(),
    height = 5,
    as_panel = true,
    on_draw::Union{Nothing,Function} = nothing,
    controls = text_widget_controls,
) = TextWidget(LiveInternals(), Measure(height, width), controls, "", as_panel, on_draw)

TextWidget(
    text::String;
    width = console_width(),
    height = Measure(text).h,
    as_panel = true,
    on_draw::Union{Nothing,Function} = nothing,
    controls = text_widget_controls,
) = TextWidget(
    LiveInternals(), 
    Measure(height, width), 
    controls, 
    text, as_panel, on_draw
)

# ----------------------------------- frame ---------------------------------- #
function frame(tw::TextWidget; kwargs...)
    isnothing(tw.on_draw) || on_draw(tw)

    tw.as_panel && return Panel(
        tw.text,
        width = tw.measure.w,
        height = tw.measure.h + 1,
        fit = false,
        style = "dim",
    )

    txt = reshape_text(tw.text, tw.measure.w - 4)
    tw.text = txt

    lines = split(txt, "\n")
    lines = lines[1:min(tw.measure.h, length(lines))]

    return RenderableText(join(lines, "\n"))
end

# ---------------------------------------------------------------------------- #
#                                   INPUT BOX                                  #
# ---------------------------------------------------------------------------- #

# ------------------------------- constructors ------------------------------- #
"""
InputBox collects and displays user input as text. 
"""
@with_repr mutable struct InputBox <: AbstractWidget
    internals::LiveInternals
    measure::Measure
    controls::AbstractDict
    input_text::Union{Nothing,String}
    blinker_update::Int
    blinker_status::Symbol
    panel_kwargs
    on_draw::Union{Nothing,Function}
end



"""
- {bold white}enter{/bold white}: new line
"""
newline(ib::InputBox, ::Enter) = isnothing(ib.input_text) || (ib.input_text *= "\n")

addspace(ib::InputBox, ::SpaceBar) = isnothing(ib.input_text) || (ib.input_text *= " ")

del(ib::InputBox, ::Del) = isnothing(ib.input_text) || begin
    textwidth(ib.input_text) > 0 && (ib.input_text = ib.input_text[1:(end - 1)])
end

addchar(ib::InputBox, c::Char) = if isnothing(ib.input_text)
        ib.input_text = string(c)
    else
        ib.input_text *= c
end

input_box_controls = Dict(
    Enter() => newline,
    SpaceBar() => addspace, 
    Del() => del,
    Esc() => quit,
    Char => addchar,
)



function InputBox(;
    height = 20,
    width = console_width(),
    on_draw::Union{Nothing,Function} = nothing,
    controls::AbstractDict = input_box_controls,
    kwargs...,
)
    InputBox(LiveInternals(), Measure(height, width), controls, nothing, 0, :off, kwargs, on_draw)
end

# ----------------------------------- frame ---------------------------------- #
function frame(ib::InputBox; kwargs...)
    isnothing(ib.on_draw) || on_draw(ib)

    # create blinking symbol
    currtime = Dates.value(now())
    if currtime - ib.blinker_update > 400
        ib.blinker_update = currtime
        ib.blinker_status = ib.blinker_status == :on ? :off : :on
    end
    blinker = ib.blinker_status == :on ? " " : "{on_white} {/on_white}"

    # get text to display
    text = isnothing(ib.input_text) ? "{dim}start typing...{/dim}" : ib.input_text * blinker

    return Panel(text; width = ib.measure.w, height = ib.measure.h, ib.panel_kwargs...)
end
