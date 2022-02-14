module segment
    include("measure.jl")

    import ..style: MarkupStyle, extract_style

    export Segment

    """
        Segment

    stores one piece of text with all the styles applied to it.
    """
    struct Segment
        text::AbstractString
        styles::Vector{MarkupStyle}
        measure::Measure
    end

    """
        Segment(text::AbstractString)
    
    Constructs a Segment out of a string.
    """
    Segment(text::AbstractString) = Segment(text, extract_style(text), Measure(text))


    Base.show(io::IO, seg::Segment) = print(io, "Segment \e[2m($(length(seg.styles)) styles; size: $(seg.measure))\e[0m")

end