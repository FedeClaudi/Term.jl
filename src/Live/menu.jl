abstract type AbstractMenu <: AbstractLiveDisplay end

# --------------------------------- controls --------------------------------- #
function key_press(mn::AbstractMenu, ::ArrowDown) 
    mn.active = min(mn.active+1, mn.n_titles)
end
function key_press(mn::AbstractMenu, ::ArrowUp) 
    mn.active =  max(1, mn.active-1)
end

function key_press(mn::AbstractMenu, ::Enter)
    return mn.active
end


# ----------------------------------- frame ---------------------------------- #
function frame(mn::AbstractMenu)
    titles = map(
        i -> i == mn.active ? mn.active_titles[i] : mn.inactive_titles[i], 1:mn.n_titles
    ) 
    return vstack(titles)
end


# ---------------------------------------------------------------------------- #
#                                CONCRETE MENUS                                #
# ---------------------------------------------------------------------------- #

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





