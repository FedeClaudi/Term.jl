
"""
    AbstractMenu

Objects of type AbstractMenu present the user with a few options
and let them select one by moving around with the up/down keys 
and using Enter to select an option.
"""
abstract type AbstractMenu <: AbstractLiveDisplay end

# --------------------------------- controls --------------------------------- #
""" 
- ArrowDown: select a next option if one is available
"""
function key_press(mn::AbstractMenu, ::ArrowDown) 
    mn.active = min(mn.active+1, mn.n_titles)
end

"""
- ArrowUp: select a previos option if one is available
"""
function key_press(mn::AbstractMenu, ::ArrowUp) 
    mn.active =  max(1, mn.active-1)
end

"""
- Enter: select the current option.
"""
function key_press(mn::AbstractMenu, ::Enter)
    return mn.active
end


# ----------------------------------- frame ---------------------------------- #
"""
Render the current state of a menu live renderable.
"""
function frame(mn::AbstractMenu)
    titles = map(
        i -> i == mn.active ? mn.active_titles[i] : mn.inactive_titles[i], 1:mn.n_titles
    ) 
    return vstack(titles)
end


# ---------------------------------------------------------------------------- #
#                                CONCRETE MENUS                                #
# ---------------------------------------------------------------------------- #

"""
    mutable struct SimpleMenu <: AbstractMenu
        internals::LiveInternals
        measure::Measure
        active_titles::Vector{String}
        inactive_titles::Vector{String}
        n_titles::Int
        active::Int
    end

Simple text based menu. Each option is a string with different styling based
on wether it is highlighted or not.
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
    mutable struct ButtonsMenu <: AbstractMenu
        internals::LiveInternals
        measure::Measure
        active_titles::Vector{String}
        inactive_titles::Vector{String}
        n_titles::Int
        active::Int
    end

Menu variant in which each option is a `Panel` to make it look 
more like a button. Different styling is applied to the 
currently selected option.
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








