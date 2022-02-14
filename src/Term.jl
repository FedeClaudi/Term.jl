module Term
    include("_ansi.jl")

    include("__text_utils.jl")

    include("measure.jl")

    include("markup.jl")
    include("color.jl")
    include("style.jl")
    include("segment.jl")
    
    using .markup: extract_markup, MarkupTag

    using .color: NamedColor, BitColor, RGBColor, get_color

    using .style: MarkupStyle, extract_style

    using .segment: Segment
end

