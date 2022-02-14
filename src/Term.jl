module Term
    include("_ansi.jl")

    include("__text_utils.jl")

    include("markup.jl")
    include("color.jl")
    
    using .markup: extract_markup, MarkupTag

    using .color: NamedColor, BitColor, RGBColor, get_color
end

