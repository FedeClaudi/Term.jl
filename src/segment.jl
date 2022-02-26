module segment
    import Term: remove_markup, remove_ansi
    import ..style: apply_style, MarkupStyle
    import ..measure: Measure
    
    export Segment

    # ---------------------------------------------------------------------------- #
    #                                    SEGMENT                                   #
    # ---------------------------------------------------------------------------- #

    """
        Segment

    stores one piece of text with all the styles applied to it.
    """
    struct Segment
        text::AbstractString   # text with ANSI codes injected
        plain::AbstractString  # plain text with no style
        measure::Measure       # measure of plain text
    end

    # ------------------------------- constructors ------------------------------- #
    """
        Segment(text::AbstractString)
    
    Constructs a Segment out of a string with markup.
    """
    function Segment(text::Union{Segment, AbstractString})
        if typeof(text) == Segment
            return text
        end
        plain = remove_ansi(remove_markup(text))
        Segment(remove_markup(apply_style(text)), plain, Measure(plain))
    end

    """
        Segment(text::Union{Segment, AbstractString}, markup::AbstractString)
    
    Constructs a Segment out of a plain string and a markup string with style info
    """
    Segment(text::Union{Segment, AbstractString}, markup::Union{Nothing, AbstractString}) = isnothing(markup) ? Segment(text) : Segment("[$markup]"*text)

    """
        Segment(text::Union{Segment, AbstractString}, style::MarkupStyle)
    
    Constructs a Segment out of a plain string and a MarkupStyle object.
    """
    function Segment(text::Union{Segment, AbstractString}, style::Union{Nothing, MarkupStyle}) 
        if isnothing(style)
            Segment(text, text, Measure(text))
        else
            Segment(apply_style(text, style), text, Measure(text))
        end
    end

    Segment(text::Union{AbstractString, Segment}, null::Nothing) = Segment(text)

    

    # --------------------------------- printing --------------------------------- #
    """print styled in stdout, info otherwise"""
    function Base.show(io::IO, seg::Segment)
        if io == stdout 
            print(io, seg.text)

        else    
            print(io, "Segment \e[2m(size: $(seg.measure))\e[0m")
        end
    end

    """
    concatenate strings and segments
    """
    Base.:*(seg::Segment, str::AbstractString) = Segment(seg.text*str)
    Base.:*(str::AbstractString, seg::Segment) = Segment(str*seg.text)
    Base.:*(seg1::Segment, seg2::Segment) = Segment(seg1.text * seg2.text)



end