module segment
    include("measure.jl")

    import ..style: apply_style, MarkupStyle
    import ..markup: remove_markup

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
        plain = remove_markup(text)
        Segment(apply_style(text), plain, Measure(plain))
    end

    """
        Segment(text::AbstractString, markup::AbstractString)
    
    Constructs a Segment out of a plain string and a markup string with style info
    """
    Segment(text::AbstractString, markup::AbstractString) = Segment("[$markup]"*text)

    """
        Segment(text::AbstractString, style::MarkupStyle)
    
    Constructs a Segment out of a plain string and a MarkupStyle object.
    """
    Segment(text::AbstractString, style::MarkupStyle) = Segment(apply_style(text, style), text, Measure(text))

    """print styled in stdout, info otherwise"""
    function Base.show(io::IO, seg::Segment)
        if io == stdout 
            print(io, seg.text)
        elseif io == stderr
            print(io, "err")
        else    
            print(io, "Segment \e[2m(size: $(seg.measure))\e[0m")
        end
    end

    

    Base.show(io::IO, m::MIME"text/plain", seg::Segment) = print(io, seg.plain)
end