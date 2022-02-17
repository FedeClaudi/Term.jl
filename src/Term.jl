module Term
    # general utils
    include("__text_utils.jl")
    include("_ansi.jl")
    
    # don't import other modules
    include("measure.jl")
    include("color.jl")

    # rely on other modules
    include("markup.jl")
    include("style.jl")
    include("segment.jl")

    # renderables, rely heavily on other modules
    include("box.jl")
    include("renderables.jl")
    include("layout.jl")
    include("panel.jl")

    # ----------------------------------- base ----------------------------------- #
    import .measure
    using .measure: Measure

    # ----------------------------------- style ---------------------------------- #
    using .markup: extract_markup, MarkupTag

    using .color: NamedColor, BitColor, RGBColor, get_color

    using .style: MarkupStyle, extract_style

    using .segment: Segment

    """
        Measure(seg::Segment) 

    gives the measure of a segment
    """
    measure.Measure(seg::Segment) = seg.measure

    """
        Measure(segments::Vector{Segment})
    
    gives the measure of a vector of segments
    """
    function measure.Measure(segments::Vector{Segment})
        return Measure(
            max([seg.measure.w for seg in segments]...),
            sum([seg.measure.h for seg in segments])
        )
    end

    # -------------------------------- renderables ------------------------------- #
    using .box

    using .renderables: AbstractRenderable, Renderable, RenderableText

    using .layout: Padding, vstack, hstack

    using .panel: Panel
end

