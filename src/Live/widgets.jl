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
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
    text::String
    as_panel::Bool
    on_draw::Union{Nothing,Function}
end

text_widget_controls = Dict(
    'q' => quit,
    Esc() => quit,
)

TextWidget(
    text::String;
    as_panel = false,
    on_draw::Union{Nothing,Function} = nothing,
    controls = text_widget_controls,
) = TextWidget(
    Measure(Measure(text).h, console_width()), 
    controls, 
    nothing,
    text, as_panel, on_draw
)

on_layout_change(t::TextWidget, m::Measure) = t.measure = m

# ----------------------------------- frame ---------------------------------- #
function frame(tw::TextWidget; kwargs...)
    isnothing(tw.on_draw) || tw.on_draw(tw)

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

    return RenderableText(join(lines, "\n"); width=tw.measure.w-4)
end

# ---------------------------------------------------------------------------- #
#                                   INPUT BOX                                  #
# ---------------------------------------------------------------------------- #

# ------------------------------- constructors ------------------------------- #
"""
InputBox collects and displays user input as text. 
"""
@with_repr mutable struct InputBox <: AbstractWidget
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
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
    on_draw::Union{Nothing,Function} = nothing,
    controls::AbstractDict = input_box_controls,
    kwargs...,
)
    InputBox(
        Measure(5, console_width()),
        controls,
        nothing, 
        nothing,
        0, :off, kwargs, on_draw
        )
end

on_layout_change(ib::InputBox, m::Measure) = ib.measure = m

# ----------------------------------- frame ---------------------------------- #
function frame(ib::InputBox; kwargs...)
    isnothing(ib.on_draw) || ib.on_draw(ib)

    # create blinking symbol
    currtime = Dates.value(now())
    if currtime - ib.blinker_update > 300
        ib.blinker_update = currtime
        ib.blinker_status = ib.blinker_status == :on ? :off : :on
    end
    blinker =  if isactive(ib)
        ib.blinker_status == :on ? " " : "{on_white} {/on_white}"
    else
        ""
    end

    # get text to display
    text = isnothing(ib.input_text) ? "{dim}start typing...{/dim}" : ib.input_text * blinker

    return Panel(text; width = ib.measure.w, height = ib.measure.h, ib.panel_kwargs...)
end
