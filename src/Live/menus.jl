# ---------------------------------------------------------------------------- #
#                                 ABSTRACT MENU                                #
# ---------------------------------------------------------------------------- #
"""
    AbstractMenu

Objects of type AbstractMenu present the user with a few options
and let them select one by moving around with the up/down keys 
and using Enter to select an option.
"""
abstract type AbstractMenu <: AbstractWidget end

# --------------------------------- controls --------------------------------- #
""" 
- {bold white}arrow down/right{/bold white}: select a next option if one is available
"""
function key_press(mn::AbstractMenu, ::Union{ArrowRight,ArrowDown})
    mn.active = min(mn.active + 1, mn.n_titles)
end

"""
- {bold white}arrow up/left{/bold white}: select a previos option if one is available
"""
function key_press(mn::AbstractMenu, ::Union{ArrowLeft,ArrowUp})
    mn.active = max(1, mn.active - 1)
end

"""
- {bold white}enter{/bold white}: select the current option, quit program and return selection.
"""
function key_press(mn::AbstractMenu, ::Enter)
    mn.internals.should_stop = true
    return mn.active
end

# ----------------------------------- frame ---------------------------------- #
"""
Render the current state of a menu widget.
"""
function frame(mn::AbstractMenu; kwargs...)
    titles = map(
        i -> i == mn.active ? mn.active_titles[i] : mn.inactive_titles[i],
        1:(mn.n_titles),
    )
    return if mn.layout == :vertical
        vstack(titles...)
    else
        hstack(titles...)
    end
end

# ---------------------------------------------------------------------------- #
#                                CONCRETE MENUS                                #
# ---------------------------------------------------------------------------- #
# -------------------------------- simple menu ------------------------------- #
"""
Simple text based menu. 
The currently selected option is highlighted with a different style.
"""
@with_repr mutable struct SimpleMenu <: AbstractMenu
    internals::LiveInternals
    measure::Measure
    active_titles::Vector{String}
    inactive_titles::Vector{String}
    n_titles::Int
    active::Int
    layout::Symbol

    function SimpleMenu(
        titles::Vector;
        width = default_width(),
        active_style::String = "white bold",
        inactive_style::String = "dim",
        active_symbol = "❯",
        layout::Symbol = :vertical,
    )
        max_titles_width =
            layout == :vertical ?
            min(width, maximum(get_width.(titles)) + textwidth(active_symbol) + 1) : width

        active_titles =
            map(
                t -> RenderableText(
                    active_symbol * " " * t;
                    style = active_style,
                    width = max_titles_width,
                ),
                titles,
            ) .|>
            string |>
            collect

        inactive_titles =
            map(
                t -> RenderableText(
                    " "^(textwidth(active_symbol) + 1) * t;
                    style = inactive_style,
                    width = max_titles_width,
                ),
                titles,
            ) .|>
            string |>
            collect

        return new(
            LiveInternals(),
            Measure(length(titles), width),
            active_titles,
            inactive_titles,
            length(titles),
            1,
            layout,
        )
    end
end

# ------------------------------- buttons menu ------------------------------- #
"""
Simple menu in which each option is a `Panel` object.
Styling reflects which option is currently selected
"""
@with_repr mutable struct ButtonsMenu <: AbstractMenu
    internals::LiveInternals
    measure::Measure
    active_titles::Vector{String}
    inactive_titles::Vector{String}
    n_titles::Int
    active::Int
    layout::Symbol

    function ButtonsMenu(
        titles::Vector;
        width::Int = console_width(),
        active_color::Union{Vector,String} = "black",
        active_background::Union{Vector,String} = "white",
        inactive_color::Union{Vector,String} = "dim",
        inactive_background::Union{Vector,String} = "default",
        justify::Symbol = :center,
        box::Symbol = :SQUARE,
        layout::Symbol = :vertical,
        height::Union{Nothing,Int} = nothing,
        panel_kwargs...,
    )

        # get parameters for each button
        n = length(titles)
        active_color = active_color isa String ? repeat([active_color], n) : active_color
        active_background =
            active_background isa String ? repeat([active_background], n) :
            active_background
        inactive_color =
            inactive_color isa String ? repeat([inactive_color], n) : inactive_color
        inactive_background =
            inactive_background isa String ? repeat([inactive_background], n) :
            inactive_background
        @assert length(active_color) == n "Incorrect number of values for `active_color`"
        @assert length(active_background) == n "Incorrect number of values for `active_background`"
        @assert length(inactive_color) == n "Incorrect number of values for `inactive_color`"
        @assert length(inactive_background) == n "Incorrect number of values for `inactive_background`"

        # make a panel for each button
        active_titles, inactive_titles = Panel[], Panel[]
        button_width = layout == :vertical ? width : fint(width / n)
        button_height = layout == :vertical ? fint(height/n) : height

        for (i, t) in enumerate(titles)
            push!(
                active_titles,
                Panel(
                    "{$(active_color[i]) on_$(active_background[i])}" *
                    t *
                    "{/$(active_color[i]) on_$(active_background[i])}";
                    background = active_background[i],
                    style = "$(active_color[i]) on_$(active_background[i])",
                    width = button_width,
                    justify = justify,
                    box = box,
                    height = button_height,
                    padding = (1, 1, 1, 1),
                ),
            )

            push!(
                inactive_titles,
                Panel(
                    "{$(inactive_color[i]) on_$(inactive_background[i])}" *
                    t *
                    "{/$(inactive_color[i]) on_$(inactive_background[i])}";
                    background = inactive_background[i],
                    style = inactive_color[i],
                    width = button_width,
                    justify = justify,
                    box = box,
                    height = button_height,
                    padding = (1, 1, 1, 1),
                ),
            )
        end

        measure = if layout == :vertical
            Measure(something(height, length(titles)), width)
        else
            hmax = maximum(map(p -> p.measure.h, inactive_titles))
            Measure(something(height, hmax), width)
        end

        return new(
            LiveInternals(),
            measure,
            string.(active_titles),
            string.(inactive_titles),
            length(titles),
            1,
            layout,
        )
    end
end

# ---------------------------------------------------------------------------- #
#                                 MULTI SELECT                                 #
# ---------------------------------------------------------------------------- #

"""
Menu variant for selecting multiple options. 
Color indicates current active option, ticks selected options
"""
@with_repr mutable struct MultiSelectMenu <: AbstractMenu
    internals::LiveInternals
    measure::Measure
    options::Vector
    active_style::String
    inactive_style::String
    options_width::Int
    selected::Vector{Int}
    active::Int
    n_titles::Int
    selected_sym::String
    notselected_sym::String

    function MultiSelectMenu(
        options::Vector;
        active_style::String = "white bold",
        inactive_style::String = "dim",
        width::Int = console_width(),
    )
        selected_sym = apply_style("✔ ", active_style)
        notselected_sym = apply_style("□ ", inactive_style)

        max_titles_width = min(width, maximum(get_width.(options)) + 2)

        new(
            LiveInternals(),
            Measure(length(options), width),
            options,
            active_style,
            inactive_style,
            max_titles_width,
            Int[],
            1,
            length(options),
            selected_sym,
            notselected_sym,
        )
    end
end

"""
- {bold white}enter{bold white}: return selected options
"""
function key_press(mn::MultiSelectMenu, ::Enter)
    mn.internals.should_stop = true
    return mn.selected
end

"""
- {bold white}space bar{/bold white}: select current option
"""
function key_press(mn::MultiSelectMenu, ::SpaceBar)
    active = mn.active
    if active ∈ mn.selected
        deleteat!(mn.selected, mn.selected .== active)
    else
        push!(mn.selected, active)
    end
end

function frame(mn::MultiSelectMenu; kwargs...)
    make_option(i::Int, isactive::Bool, isselected::Bool) = begin
        sym = isselected ? mn.selected_sym : mn.notselected_sym
        style = isactive ? mn.active_style : mn.inactive_style

        RenderableText(
            sym * "{$style}" * mn.options[i] * "{/$style}";
            width = mn.options_width,
        )
    end

    options = map(i -> make_option(i, i == mn.active, i ∈ mn.selected), 1:(mn.n_titles))
    return vstack(options)
end
