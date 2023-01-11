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

menu_activate_next(mn::AbstractMenu, ::Any) = mn.active = min(mn.active + 1, mn.n_titles)

menu_activate_prev(mn::AbstractMenu, ::Any) = mn.active = max(1, mn.active - 1)

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
    'h' => toggle_help,
)


hor_menu_controls = Dict(
    ArrowRight() => menu_activate_next,
    ArrowLeft() => menu_activate_prev,
    Enter() => menu_return_value,
    Esc() => quit,
    'q' => quit,
    'h' => toggle_help,
)

# ----------------------------------- frame ---------------------------------- #
"""
Render the current state of a menu widget.
"""
function frame(mn::AbstractMenu; kwargs...)
    isnothing(mn.on_draw) || on_draw(mn)

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
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
    active_titles::Vector{String}
    inactive_titles::Vector{String}
    n_titles::Int
    active::Int
    layout::Symbol
    on_draw::Union{Nothing,Function}

    function SimpleMenu(
        titles::Vector;
        controls::Union{Nothing, AbstractDict} = nothing,
        width = default_width(),
        active_style::String = "white bold",
        inactive_style::String = "dim",
        active_symbol = "❯",
        layout::Symbol = :vertical,
        on_draw::Union{Nothing,Function} = nothing,
    )

        controls = something(controls,
            layout == :vertical ? vert_menu_controls : hor_menu_controls
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
            Measure(length(titles), width),
            controls,
            nothing,
            active_titles,
            inactive_titles,
            length(titles),
            1,
            layout,
            on_draw,
        )
    end
end

# ------------------------------- buttons menu ------------------------------- #
"""
Simple menu in which each option is a `Panel` object.
Styling reflects which option is currently selected
"""
@with_repr mutable struct ButtonsMenu <: AbstractMenu
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
    active_titles::Vector{String}
    inactive_titles::Vector{String}
    n_titles::Int
    active::Int
    layout::Symbol
    on_draw::Union{Nothing,Function}

    function ButtonsMenu(
        titles::Vector;
        controls::Union{Nothing, AbstractDict} = nothing,
        width::Int = console_width(),
        active_color::Union{Vector,String} = "black",
        active_background::Union{Vector,String} = "white",
        inactive_color::Union{Vector,String} = "dim",
        inactive_background::Union{Vector,String} = "default",
        justify::Symbol = :center,
        box::Symbol = :SQUARE,
        layout::Symbol = :vertical,
        height::Union{Nothing,Int} = nothing,
        on_draw::Union{Nothing,Function} = nothing,
        panel_kwargs...,
    )

        controls = something(controls,
            layout == :vertical ? vert_menu_controls : hor_menu_controls
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
        button_height = layout == :vertical ? fint(height / n) : height

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
            measure,
            controls,
            nothing,
            string.(active_titles),
            string.(inactive_titles),
            length(titles),
            1,
            layout,
            on_draw,
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
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
    options::Vector
    active_style::String
    inactive_style::String
    options_width::Int
    selected::Vector{Int}
    active::Int
    n_titles::Int
    selected_sym::String
    notselected_sym::String
    on_draw::Union{Nothing,Function}
end

function menu_return_value(mn::MultiSelectMenu, ::Enter)
    quit(mn)
    return mn.selected
end

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
    'h' => toggle_help,
)


function MultiSelectMenu(
    options::Vector;
    controls::AbstractDict = multi_select_controls,
    active_style::String = "white bold",
    inactive_style::String = "dim",
    width::Int = console_width(),
    on_draw::Union{Nothing,Function} = nothing,
)
    selected_sym = apply_style("✔ ", active_style)
    notselected_sym = apply_style("□ ", inactive_style)

    max_titles_width = min(width, maximum(get_width.(options)) + 2)

    MultiSelectMenu(
        Measure(length(options), width),
        controls,
        nothing,
        options,
        active_style,
        inactive_style,
        max_titles_width,
        Int[],
        1,
        length(options),
        selected_sym,
        notselected_sym,
        on_draw,
    )
end


function frame(mn::MultiSelectMenu; kwargs...)
    isnothing(mn.on_draw) || on_draw(mn)

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
