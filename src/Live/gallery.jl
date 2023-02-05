"""
A `Gallery` containes multiple widgets, but only shows one at the time. 
"""
@with_repr mutable struct Gallery <: AbstractWidgetContainer
    internals::WidgetInternals
    controls::AbstractDict
    widgets::Vector{AbstractWidget}
    active::Int
    show_panel::Bool
    title::String
end

gallery_controls = Dict(
    ArrowRight() => activate_next_widget,
    ArrowLeft() => activate_prev_widget,
    'q' => quit,
    Esc() => quit,
)

function Gallery(
    widgets::Vector;
    controls = gallery_controls,
    height::Int = console_height() - 5,
    width::Int = console_width(),
    show_panel::Bool = true,
    title::String = "Widget",
    on_draw::Union{Nothing,Function} = nothing,
    on_activated::Function = on_activated,
    on_deactivated::Function = on_deactivated,
)
    # set widgets size
    Δ = show_panel ? 4 : 0
    measure = Measure(height, width)
    for wdg in widgets
        on_layout_change(wdg, Measure(measure.h - Δ, measure.w - Δ))
    end

    gal = Gallery(
        WidgetInternals(measure, nothing, on_draw, on_activated, on_deactivated, false),
        controls,
        widgets,
        1,
        show_panel,
        title,
    )
    set_as_parent(gal)
    return gal
end

function on_layout_change(gal::Gallery, m::Measure)
    gal.internals.measure = m
    Δ = gal.show_panel ? 4 : 0
    for wdg in gal.widgets
        on_layout_change(wdg, Measure(m.h - Δ, m.w - Δ))
    end
end

# ----------------------------------- frame ---------------------------------- #
function frame(gal::Gallery; kwargs...)
    isnothing(gal.internals.on_draw) || gal.internals.on_draw(gal)

    content = frame(get_active(gal))
    gal.show_panel || return content

    style = gal.show_panel && isactive(gal) ? "dim" : "hidden"

    Panel(
        content;
        title = gal.show_panel ? "$(gal.title) $(gal.active)/$(length(gal.widgets))" :
                nothing,
        justify = :center,
        style = style,
        title_style = "default",
        title_justify = :center,
        fit = false,
        width = gal.internals.measure.w,
        height = gal.internals.measure.h,
        padding = (1, 1, 1, 1),
    )
end
