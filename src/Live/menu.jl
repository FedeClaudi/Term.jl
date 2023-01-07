
"""
    AbstractMenu

Objects of type AbstractMenu present the user with a few options
and let them select one by moving around with the up/down keys 
and using Enter to select an option.
"""
abstract type AbstractMenu <: AbstractWidget end

# --------------------------------- controls --------------------------------- #
""" 
- {bold white}arrow down{/bold white}: select a next option if one is available
"""
function key_press(mn::AbstractMenu, ::ArrowDown) 
    mn.active = min(mn.active+1, mn.n_titles)
end

"""
- {bold white}arrow up{/bold white}: select a previos option if one is available
"""
function key_press(mn::AbstractMenu, ::ArrowUp) 
    mn.active =  max(1, mn.active-1)
end

"""
- {bold white}enter{/bold white}: select the current option.
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
        i -> i == mn.active ? mn.active_titles[i] : mn.inactive_titles[i], 1:mn.n_titles
    ) 
    return vstack(titles)
end


# ---------------------------------------------------------------------------- #
#                                CONCRETE MENUS                                #
# ---------------------------------------------------------------------------- #

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

    function SimpleMenu(
        titles::Vector;
        width=default_width(),
        active_style::String="white bold",
        inactive_style::String="dim",
        active_symbol="❯",
        )
        
        max_titles_width = min(width, maximum(get_width.(titles)) + textwidth(active_symbol)+1) 
        active_titles = map(t -> 
            RenderableText(
                    active_symbol*" "*t;
                    style=active_style,
                    width=max_titles_width
            ), titles) .|> string |> collect
            
        inactive_titles = map(t -> 
            RenderableText(
                    " "^(textwidth(active_symbol)+1)*t;
                    style=inactive_style,
                    width=max_titles_width
            ), titles) .|> string |> collect
    
        return new(
            LiveInternals(), 
            Measure(length(titles), width),
            active_titles,
            inactive_titles,
            length(titles),
            1,
            )
    end
end


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

    function ButtonsMenu(
        titles::Vector;
        width=default_width(),
        active_color::String="black",
        active_background::String="white",
        inactive_color::String="dim",
        justify::Symbol=:center,
        box::Symbol = :SQUARE,
        panel_kwargs...
        )
        
        active_titles = map(t -> 
            Panel(
                    "{$(active_color) on_$(active_background)}"*t*"{/$(active_color) on_$(active_background)}";
                    background=active_background,
                    style="$(active_color) on_$(active_background)",
                    width=width,
                    justify=justify,
                    box=box,
                    padding=(1, 1, 1, 1)
            )
            , titles) .|> string |> collect

        inactive_titles = map(t -> 
        Panel(
            t;
            background="default",
            style=inactive_color,
            width=width,
            justify=justify,
            box=box,
            padding=(1, 1, 1, 1)
    )
            , titles) .|> string |> collect
    
        return new(
            LiveInternals(), 
            Measure(length(titles), width),
            active_titles,
            inactive_titles,
            length(titles),
            1,
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
        active_style::String="white bold",
        inactive_style::String="dim",
        width::Int=console_width(),
    )

        selected_sym = apply_style("✔ ", active_style)
        notselected_sym = apply_style("□ ", inactive_style)
        
        max_titles_width = min(
            width, 
            maximum(get_width.(options)) + 2
        ) 

        new(LiveInternals(), Measure(length(options), width), options, active_style, inactive_style, max_titles_width, Int[], 1, length(options), selected_sym, notselected_sym)
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
        width=mn.options_width,
        
        )
    end

    options = map(
        i -> make_option(i, i == mn.active, i ∈ mn.selected), 1:mn.n_titles
    )
    return vstack(options)
end