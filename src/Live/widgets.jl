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
    internals::WidgetInternals
    controls::AbstractDict
    text::String
    as_panel::Bool
    panel_kwargs
end

text_widget_controls = Dict(
    'q' => quit,
    Esc() => quit,
)

TextWidget(
    text::String;
    as_panel = false,
    on_draw::Union{Nothing,Function} = nothing,
    on_highlighted::Function = on_highlighted,
    on_not_highlighted::Function = on_not_highlighted,
    controls = text_widget_controls,
    kwargs...
) = TextWidget(
    Measure(Measure(text).h, console_width()), 
    controls, 
    nothing,
    text, as_panel, on_draw, 
    on_highlighted, on_not_highlighted,
    kwargs
)

on_layout_change(t::TextWidget, m::Measure) = t.measure = m

# ----------------------------------- frame ---------------------------------- #
function frame(tw::TextWidget; kwargs...)
    isnothing(tw.on_draw) || tw.on_draw(tw)

    tw.as_panel && return Panel(
        tw.text;
        width = tw.measure.w,
        height = tw.measure.h,
        fit = false,
        tw.panel_kwargs...
    )

    txt = reshape_text(tw.text, tw.measure.w - 4)
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
    internals::WidgetInternals
    controls::AbstractDict
    input_text::Union{Nothing,String}
    blinker_update::Int
    blinker_status::Symbol
    panel_kwargs
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
    controls::AbstractDict = input_box_controls,
    on_draw::Union{Nothing,Function} = nothing,
    on_highlighted::Function = on_highlighted,
    on_not_highlighted::Function = on_not_highlighted,
    kwargs...,
)
    InputBox(
        Measure(5, console_width()),
        controls,
        nothing, 
        nothing,
        0, :off, kwargs, on_draw, on_highlighted, on_not_highlighted
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


# ---------------------------------------------------------------------------- #
#                                  PLACEHOLDER                                 #
# ---------------------------------------------------------------------------- #


mutable struct PlaceHolderWidget <: AbstractWidget
    internals::WidgetInternals
    controls::AbstractDict
    color::String
    style::String
    name::String
end

on_layout_change(ph::PlaceHolderWidget, m::Measure) = ph.internals.measure = m


function on_highlighted(ph::PlaceHolderWidget)
    ph.internals.is_highlighted = true
    ph.style = "bold"
end
function on_not_highlighted(ph::PlaceHolderWidget)
    ph.internals.is_highlighted = false
    ph.style = "dim"
end

function PlaceHolderWidget(
    h::Int, w::Int, name::String, color::String;
    on_draw::Union{Nothing,Function} = nothing,
    on_highlighted::Function = on_highlighted,
    on_not_highlighted::Function = on_not_highlighted,
    )
    internals = WidgetInternals(
        Measure(h, w), nothing, on_draw, on_highlighted, on_not_highlighted, false
    )

    PlaceHolderWidget(
        internals, text_widget_controls, color, "dim", name
    )
end

function frame(ph::PlaceHolderWidget; kwargs...)
    isnothing(ph.internals.on_draw) || ph.internals.on_draw(ph)

    m = ph.internals.measure
    return PlaceHolder(
        m.h, m.w;
        style="$(ph.color) $(ph.style)",
        text = "$(ph.name) ($(m.h), $(m.w)"
    )
end

