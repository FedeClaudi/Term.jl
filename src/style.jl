module style
    include("__text_utils.jl")
    include("_ansi.jl")
    import Parameters: @with_kw

    import ..markup: MarkupTag
    import ..color: AbstractColor, NamedColor, is_color, is_background, get_color

    export MarkupStyle

    is_mode(string::AbstractString) = string ∈ NAMED_MODES


    # ---------------------------------------------------------------------------- #
    #                                    STYLEX                                    #
    # ---------------------------------------------------------------------------- #
    """
        MarkupStyle

    Holds information about the style specification set out by a 
    `MarkupTag`.
    """
    @with_kw mutable struct MarkupStyle
        bold::Bool          = false
        dim::Bool           = false
        italic::Bool        = false
        underline::Bool     = false
        blink::Bool      = false
        inverse::Bool       = false
        hidden::Bool        = false
        striked::Bool       = false

        color::AbstractColor       = NamedColor("default")
        background::AbstractColor       = NamedColor("default")

        tag::MarkupTag
    end

    """
        MarkupStyle(tag::MarkupTag)

    Builds a MarkupStyle definition from a MarkupTag.
    """
    function MarkupStyle(tag::MarkupTag)
        codes = split(unspace_commas(tag.markup))

        style = MarkupStyle(tag=tag)
        for code in codes
            if is_mode(code)
                setproperty!(style, Symbol(code), true)
            elseif is_color(code)
                setproperty!(style, :color, get_color(code))
            elseif is_background(code)
                setproperty!(style, :background, get_color(code; bg=true))
            else
                @warn "Code type not recognized: $code"
            end
        end
        return style
    end


end