"""
A `Gallery` containes multiple widgets, but only shows one at the time. 
"""
@with_repr mutable struct Gallery <: AbstractWidgetContainer
    internals::LiveInternals
    measure::Measure
    widgets::Vector{AbstractWidget}
    active::Int
    show_panel::Bool
end

function Gallery(
    widgets::Vector;
    height::Int = console_height() - 5,
    width::Int = console_width(),
    show_panel::Bool=true
)
    # measure widgets
    widgets_measures = getfield.(widgets, :measure)
    max_w = maximum(getfield.(widgets_measures, :w))
    max_h = maximum(getfield.(widgets_measures, :h))

    @assert max_w < (width - 4) "Gallery width set to $width but a widget has width $max_w, $(width - max_w - 5) above the limit."
    @assert max_h < (height - 4) "Gallery width set to $height but a widget has height $max_h, $(height - max_h - 5) above the limit."

    return Gallery(LiveInternals(), Measure(height, width), widgets, 1, show_panel)
end

"""
$(default_container_commands)

- {bold white}key right{/bold white}: next gallery item
"""
key_press(gal::Gallery, ::ArrowRight) = activate_next(gal)

"""
- {bold white}key left{/bold white}: previous gallery item
"""
key_press(gal::Gallery, ::ArrowLeft) = activate_previous(gal)

key_press(gal::Gallery, key::KeyInput) = key_press(get_active(gal), key)

function key_press(gal::Gallery, ::Enter) 
    gal.internals.should_stop = true
    return nothing
end


function key_press(gal::Gallery, ::Esc) 
    gal.internals.should_stop = true
    return nothing
end

# ----------------------------------- frame ---------------------------------- #
frame(gal::Gallery; kwargs...) = Panel(
    frame(get_active(gal));
    title = gal.show_panel ? "Widget $(gal.active)/$(length(gal.widgets))" : nothing,
    justify = :center,
    style = gal.show_panel ? "dim" : "hidden",
    title_style = "default",
    title_justify = :center,
    fit = false,
    width = gal.measure.w,
    height = gal.measure.h,
    padding = (1, 1, 1, 1),
)
