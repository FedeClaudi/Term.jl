module segment
    include("measure.jl")

    import ..style: apply_style

    export Segment

    """
        Segment

    stores one piece of text with all the styles applied to it.
    """
    struct Segment
        text::AbstractString   # text with ANSI codes injected
        plain::AbstractString  # plain text with no style
        measure::Measure       # measure of plain text
    end

    """
        Segment(text::AbstractString)
    
    Constructs a Segment out of a string with markup.
    """
    function Segment(text::AbstractString)
        # plain = remove_markup(text)
        Segment(apply_style(text), text, Measure(text))
    end

    """print styled in stdout, info otherwise"""
    Base.show(io::IO, seg::Segment) = io == stdout ? print(io, seg.text) : print(io, "Segment \e[2m(size: $(seg.measure))\e[0m")
    # Base.show(io::Base.TTY, seg::Segment) = print(io, seg.text)

end