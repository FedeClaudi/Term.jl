module Term
    include("_ansi.jl")

    include("__text_utils.jl")

    include("markup.jl")

    using .markup: extract_markup, MarkupTag
end

