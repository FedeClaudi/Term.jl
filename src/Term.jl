module Term
    include("_ansi.jl")

    include("__text_utils.jl")

    include("ansi.jl")

    using .ansi: extract_markup, MarkupTag
end

