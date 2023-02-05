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

""" set next item to active """
menu_activate_next(mn::AbstractMenu, ::Any) = mn.active = min(mn.active + 1, mn.n_titles)

""" set previous item to active """
menu_activate_prev(mn::AbstractMenu, ::Any) = mn.active = max(1, mn.active - 1)

""" quit menu and return value"""
function menu_return_value(mn::AbstractMenu, ::Enter)
    quit(mn)
    return mn.active
end

vert_menu_controls = Dict(
    ArrowDown() => menu_activate_next,
    ArrowUp() => menu_activate_prev,
    Enter() => menu_return_value,
    Esc() => quit,
    'q' => quit,
)

hor_menu_controls = Dict(
    ArrowRight() => menu_activate_next,
    ArrowLeft() => menu_activate_prev,
    Enter() => menu_return_value,
    Esc() => quit,
    'q' => quit,
)

function on_layout_change(mn::AbstractMenu, m::Measure)
    mn.internals.measure = m
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
    internals::WidgetInternals
    controls::AbstractDict
    titles::Vector{String}
    n_titles::Int
    active_style::String
    inactive_style::String
    active::Int
    layout::Symbol

    function SimpleMenu(
        titles::Vector;
        controls::Union{Nothing,AbstractDict} = nothing,
        width = default_width(),
        active_style::String = "white bold",
        inactive_style::String = "dim",
        layout::Symbol = :vertical,
        on_draw::Union{Nothing,Function} = nothing,
        on_activated::Function = on_activated,
        on_deactivated::Function = on_deactivated,
    )
        controls = something(
            controls,
            layout == :vertical ? vert_menu_controls : hor_menu_controls,
        )

        return new(
            WidgetInternals(
                Measure(length(titles), width),
                nothing,
                on_draw,
                on_activated,
                on_deactivated,
                false,
            ),
            controls,
            titles,
            length(titles),
            active_style,
            inactive_style,
            1,
            layout,
        )
    end
end

""" 
    active_title(mn::SimpleMenu, i::Int, width::Int)

Return the title of the i-th item of the menu with the active style.
"""
function active_title(mn::SimpleMenu, i::Int, width::Int)
    return RenderableText(mn.titles[i]; style = mn.active_style, width = width) |> string
end

""" 
    inactive_title(mn::SimpleMenu, i::Int, width::Int)

Return the title of the i-th item of the menu with the inactive style.
"""
function inactive_title(mn::SimpleMenu, i::Int, width::Int)
    return RenderableText(mn.titles[i]; style = mn.inactive_style, width = width) |> string
end

function frame(mn::SimpleMenu; kwargs...)
    active_symbol = "❯"
    titles = mn.titles

    # get size
    m = mn.internals.measure
    max_titles_width =
        mn.layout == :vertical ?
        min(m.w, maximum(get_width.(titles)) + textwidth(active_symbol) + 1) : m.w

    # make and stack title
    titles = map(
        i ->
            i == mn.active ? active_title(mn, i, max_titles_width) :
            inactive_title(mn, i, max_titles_width),
        1:length(titles),
    )
    return if mn.layout == :vertical
        vstack(titles...)
    else
        hstack(titles...)
    end
end

# ------------------------------- buttons menu ------------------------------- #
"""
Simple menu in which each option is a `Panel` object.
Styling reflects which option is currently selected
"""
@with_repr mutable struct ButtonsMenu <: AbstractMenu
    internals::WidgetInternals
    controls::AbstractDict
    titles::Vector{String}
    active_style::Vector
    inactive_style::Vector
    active_background::Vector
    inactive_background::Vector
    n_titles::Int
    active::Int
    layout::Symbol
    panel_kwargs

    function ButtonsMenu(
        titles::Vector;
        controls::Union{Nothing,AbstractDict} = nothing,
        width::Int = console_width(),
        active_color::Union{Vector,String} = "black",
        active_background::Union{Vector,String} = "white",
        inactive_color::Union{Vector,String} = "dim",
        inactive_background::Union{Vector,String} = "default",
        layout::Symbol = :vertical,
        height::Union{Nothing,Int} = length(titles),
        on_draw::Union{Nothing,Function} = nothing,
        on_activated::Function = on_activated,
        on_deactivated::Function = on_deactivated,
        panel_kwargs...,
    )
        controls = something(
            controls,
            layout == :vertical ? vert_menu_controls : hor_menu_controls,
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

        measure = if layout == :vertical
            Measure(something(height, length(titles)), width)
        else
            hmax = layout == :vertical ? fint(height / n) : height
            Measure(something(height, hmax), width)
        end

        return new(
            WidgetInternals(measure, nothing, on_draw, on_activated, on_deactivated, false),
            controls,
            titles,
            active_color,
            inactive_color,
            active_background,
            inactive_background,
            length(titles),
            1,
            layout,
            panel_kwargs,
        )
    end
end

"""
    active_title(mn::ButtonsMenu, i::Int, width::Int, height::Int; panel_kwargs...)

Return the title of the i-th item of the menu with the active style.
"""
function active_title(mn::ButtonsMenu, i::Int, width::Int, height::Int; panel_kwargs...)
    active_color, active_background = mn.active_style[i], mn.active_background[i]
    return Panel(
        "{$(active_color) on_$(active_background)}" *
        mn.titles[i] *
        "{/$(active_color) on_$(active_background)}";
        background = active_background,
        style = "$(active_color) on_$(active_background)",
        width = width,
        justify = get(panel_kwargs, :justify, :center),
        box = get(panel_kwargs, :box, :SQUARE),
        height = height,
        panel_kwargs...,
    )
end

"""
    inactive_title(mn::ButtonsMenu, i::Int, width::Int, height::Int; panel_kwargs...)

Return the title of the i-th item of the menu with the inactive style.  
"""
function inactive_title(mn::ButtonsMenu, i::Int, width::Int, height::Int; panel_kwargs...)
    inactive_color, inactive_background = mn.inactive_style[i], mn.inactive_background[i]
    return Panel(
        "{$(inactive_color) on_$(inactive_background)}" *
        mn.titles[i] *
        "{/$(inactive_color) on_$(inactive_background)}";
        background = inactive_background,
        style = inactive_color,
        width = width,
        justify = get(panel_kwargs, :justify, :center),
        box = get(panel_kwargs, :box, :SQUARE),
        height = height,
        panel_kwargs...,
    )
end

function frame(mn::ButtonsMenu; kwargs...)
    m, n = mn.internals.measure, mn.n_titles
    button_width = mn.layout == :vertical ? m.w : fint(m.w / n)
    button_height = mn.layout == :vertical ? fint(m.h / n) : m.h

    # make and stack title
    titles = map(
        i ->
            i == mn.active ?
            active_title(mn, i, button_width, button_height; mn.panel_kwargs...) :
            inactive_title(mn, i, button_width, button_height; mn.panel_kwargs...),
        1:(mn.n_titles),
    )
    return if mn.layout == :vertical
        vstack(titles...)
    else
        hstack(titles...)
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
    internals::WidgetInternals
    controls::AbstractDict
    options::Vector
    active_style::String
    inactive_style::String
    options_width::Int
    selected::Vector{Int}
    active::Int
    n_titles::Int
    selected_sym::String
    notselected_sym::String
end

"""
quit and return selection.
"""
function menu_return_value(mn::MultiSelectMenu, ::Enter)
    quit(mn)
    return mn.selected
end

"""
Toggle selection status of current active option
"""
function multi_select_toggle(mn::MultiSelectMenu, ::SpaceBar)
    active = mn.active
    if active ∈ mn.selected
        deleteat!(mn.selected, mn.selected .== active)
    else
        push!(mn.selected, active)
    end
end

multi_select_controls = Dict(
    ArrowDown() => menu_activate_next,
    ArrowUp() => menu_activate_prev,
    SpaceBar() => multi_select_toggle,
    Enter() => menu_return_value,
    Esc() => quit,
    'q' => quit,
)

function MultiSelectMenu(
    options::Vector;
    controls::AbstractDict = multi_select_controls,
    active_style::String = "white bold",
    inactive_style::String = "dim",
    width::Int = console_width(),
    on_draw::Union{Nothing,Function} = nothing,
    on_activated::Function = on_activated,
    on_deactivated::Function = on_deactivated,
)
    selected_sym = apply_style("✔ ", active_style)
    notselected_sym = apply_style("□ ", inactive_style)

    max_titles_width = min(width, maximum(get_width.(options)) + 2)

    MultiSelectMenu(
        WidgetInternals(
            Measure(length(options), width),
            nothing,
            on_draw,
            on_activated,
            on_deactivated,
            false,
        ),
        controls,
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

function make_option(mn::MultiSelectMenu, i::Int, isactive::Bool, isselected::Bool)
    sym = isselected ? mn.selected_sym : mn.notselected_sym
    style = isactive ? mn.active_style : mn.inactive_style

    return RenderableText(
        sym * "{$style}" * mn.options[i] * "{/$style}";
        width = mn.options_width,
    )
end

function frame(mn::MultiSelectMenu; kwargs...)
    isnothing(mn.internals.on_draw) || mn.internals.on_draw(mn)

    options = map(i -> make_option(mn, i, i == mn.active, i ∈ mn.selected), 1:(mn.n_titles))
    return vstack(options)
end
