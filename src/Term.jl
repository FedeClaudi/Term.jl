module Term

    # general utils
    include("_ansi.jl")
    include("__text_utils.jl")

    # don't import other modules
    include("measure.jl")
    include("box.jl")
    include("color.jl")

    include("renderables.jl")

    # rely on other modules
    include("markup.jl")
    include("style.jl")
    include("segment.jl")
    include("layout.jl")
    include("panel.jl")


    using .box

    using .layout: Padding

    using .renderables: AbstractRenderable
    
    using .markup: extract_markup, MarkupTag

    using .color: NamedColor, BitColor, RGBColor, get_color

    using .style: MarkupStyle, extract_style

    using .segment: Segment, Segments, push!

    using .panel: Panel
end

