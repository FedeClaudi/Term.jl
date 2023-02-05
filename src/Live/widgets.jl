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

text_widget_controls = Dict('q' => quit, Esc() => quit)

TextWidget(
    text::String;
    as_panel = false,
    on_draw::Union{Nothing,Function} = nothing,
    on_activated::Function = on_activated,
    on_deactivated::Function = on_deactivated,
    controls = text_widget_controls,
    kwargs...,
) = TextWidget(
    WidgetInternals(
        Measure(Measure(text).h, console_width()),
        nothing,
        on_draw,
        on_activated,
        on_deactivated,
        false,
    ),
    controls,
    text,
    as_panel,
    Dict{Symbol,Any}(kwargs),
)

on_layout_change(t::TextWidget, m::Measure) = t.internals.measure = m

# ----------------------------------- frame ---------------------------------- #
function frame(tw::TextWidget; kwargs...)
    isnothing(tw.internals.on_draw) || tw.internals.on_draw(tw)
    measure = tw.internals.measure

    style = get(tw.panel_kwargs, :style, "default")
    style = isactive(tw) ? "bold white " * style : style

    panel_kwargs = copy(tw.panel_kwargs)
    if :style ∈ keys(tw.panel_kwargs)
        panel_kwargs[:style] = panel_kwargs[:style] * (isactive(tw) ? " bold red" : " dim")
    else
        panel_kwargs[:style] = isactive(tw) ? " bold red" : "dim"
    end

    tw.as_panel && return Panel(
        tw.text;
        width = measure.w,
        height = measure.h,
        fit = false,
        panel_kwargs...,
    )

    txt = if !isactive(tw)
        reshape_text(tw.text, measure.w - 4)
    else
        _txt = reshape_text(tw.text, measure.w - 6)
        vLine(get_height(_txt)) * _txt |> string
    end

    return RenderableText(txt; width = measure.w - 4)
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
    panel_kwargs::Dict{Symbol,Any}
end

"""
new line
"""
newline(ib::InputBox, ::Enter) = isnothing(ib.input_text) || (ib.input_text *= "\n")

""" insert space """
addspace(ib::InputBox, ::SpaceBar) = isnothing(ib.input_text) || (ib.input_text *= " ")

""" delete last character """
del(ib::InputBox, ::Del) =
    isnothing(ib.input_text) || begin
        textwidth(ib.input_text) > 0 && (ib.input_text = ib.input_text[1:(end - 1)])
    end

""" add character to input """
addchar(ib::InputBox, c::Char) =
    if isnothing(ib.input_text)
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
    on_activated::Function = on_activated,
    on_deactivated::Function = on_deactivated,
    kwargs...,
)
    InputBox(
        WidgetInternals(
            Measure(5, console_width()),
            nothing,
            on_draw,
            on_activated,
            on_deactivated,
            false,
        ),
        controls,
        nothing,
        0,
        :off,
        kwargs,
    )
end

on_layout_change(ib::InputBox, m::Measure) = ib.internals.measure = m

# ----------------------------------- frame ---------------------------------- #
function frame(ib::InputBox; kwargs...)
    isnothing(ib.internals.on_draw) || ib.internals.on_draw(ib)

    # create blinking symbol
    currtime = Dates.value(now())
    if currtime - ib.blinker_update > 300
        ib.blinker_update = currtime
        ib.blinker_status = ib.blinker_status == :on ? :off : :on
    end
    blinker = if isactive(ib)
        ib.blinker_status == :on ? " " : "{on_white} {/on_white}"
    else
        ""
    end

    panel_kwargs = copy(ib.panel_kwargs)

    panel_kwargs[:style] = get(ib.panel_kwargs, :style, "") * (isactive(ib) ? "" : " dim")
    # get text to display
    text = isnothing(ib.input_text) ? "{dim}start typing...{/dim}" : ib.input_text * blinker
    measure = ib.internals.measure
    return Panel(text; width = measure.w, height = measure.h, panel_kwargs...)
end

# ---------------------------------------------------------------------------- #
#                                  PLACEHOLDER                                 #
# ---------------------------------------------------------------------------- #

"""
Widget with no content to be used as a placeholder for choosing app layout.
"""
mutable struct PlaceHolderWidget <: AbstractWidget
    internals::WidgetInternals
    controls::AbstractDict
    color::String
    style::String
    name::String
end

on_layout_change(ph::PlaceHolderWidget, m::Measure) = ph.internals.measure = m

function on_activated(ph::PlaceHolderWidget)
    ph.internals.active = true
    ph.style = "bold"
end
function on_deactivated(ph::PlaceHolderWidget)
    ph.internals.active = false
    ph.style = "dim"
end

function PlaceHolderWidget(
    h::Int,
    w::Int,
    name::String,
    color::String;
    on_draw::Union{Nothing,Function} = nothing,
    on_activated::Function = on_activated,
    on_deactivated::Function = on_deactivated,
)
    internals = WidgetInternals(
        Measure(h, w),
        nothing,
        on_draw,
        on_activated,
        on_deactivated,
        false,
    )

    PlaceHolderWidget(internals, text_widget_controls, color, "dim", name)
end

function frame(ph::PlaceHolderWidget; kwargs...)
    isnothing(ph.internals.on_draw) || ph.internals.on_draw(ph)
    m = ph.internals.measure
    return PlaceHolder(
        m.h,
        m.w;
        style = "$(ph.color) $(ph.style)",
        text = "$(ph.name) ($(m.h), $(m.w)",
    )
end
