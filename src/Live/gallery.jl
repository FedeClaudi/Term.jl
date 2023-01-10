"""
A `Gallery` containes multiple widgets, but only shows one at the time. 
"""
@with_repr mutable struct Gallery <: AbstractWidgetContainer
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
    widgets::Vector{AbstractWidget}
    active::Int
    show_panel::Bool
    title::String
    on_draw::Union{Nothing,Function}
end



gallery_controls = Dict(
    ArrowRight() => activate_next_widget,
    ArrowLeft() => activate_prev_widget,
    'q' => quit,
    Esc() => quit,
    'h' => toggle_help,
    'w' => active_widget_help,
)


function Gallery(
    widgets::Vector;
    controls = gallery_controls,
    height::Int = console_height() - 5,
    width::Int = console_width(),
    show_panel::Bool = true,
    on_draw::Union{Nothing,Function} = nothing,
    title::String="Widget",
)
    # measure widgets
    widgets_measures = getfield.(widgets, :measure)
    max_w = maximum(getfield.(widgets_measures, :w))
    max_h = maximum(getfield.(widgets_measures, :h))

    Δ = show_panel ? 4 : 0

    @assert max_w < (width - Δ) "Gallery width set to $width but a widget has width $max_w, $(width - max_w - Δ - 1) above the limit."
    @assert max_h < (height - Δ) "Gallery height set to $height but a widget has height $max_h, $(height - max_h - Δ - 1) above the limit."

    gal = Gallery(Measure(height, width), controls, nothing, widgets, 1, show_panel, title, on_draw)
    set_as_parent(gal)
    return gal
end

# ----------------------------------- frame ---------------------------------- #
function frame(gal::Gallery; kwargs...)
    isnothing(gal.on_draw) || on_draw(gal)

    content = frame(get_active(gal))
    gal.show_panel || return content

    Panel(
        content;
        title = gal.show_panel ? "$(gal.title) $(gal.active)/$(length(gal.widgets))" : nothing,
        justify = :center,
        style = gal.show_panel ? "dim" : "hidden",
        title_style = "default",
        title_justify = :center,
        fit = false,
        width = gal.measure.w,
        height = gal.measure.h,
        padding = (1, 1, 1, 1),
    )
end
