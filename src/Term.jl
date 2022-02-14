module Term
    include("_ansi.jl")

    include("__text_utils.jl")

    include("markup.jl")
    include("color.jl")
    include("style.jl")
    
    using .markup: extract_markup, MarkupTag

    using .color: NamedColor, BitColor, RGBColor, get_color

    using .style: MarkupStyle
end

