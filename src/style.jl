module style
    include("__text_utils.jl")
    include("_ansi.jl")
    import Parameters: @with_kw

    import ..markup: MarkupTag, extract_markup, has_markup
    import ..color: AbstractColor, NamedColor, is_color, is_background, get_color

    export MarkupStyle, extract_style

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

        color::Union{Nothing, AbstractColor}       = nothing
        background::Union{Nothing, AbstractColor}       = nothing

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

    toDict(style::MarkupStyle) = Dict(fieldnames(typeof(style)) .=> getfield.(Ref(style), fieldnames(typeof(style))))

    # ------------------------------ extract style ------------------------------ #
    function extract_style(text::AbstractString)
        tags = extract_markup(text)
        styles = [MarkupStyle(tag) for tag in tags]
        return styles
    end

    # -------------------------------- apply style ------------------------------- #
    """
        apply_style(text::AbstractString, style::MarkupStyle)

    Applies a 'MarkupStyle' to a piece of text.
    """
    function apply_style(text::AbstractString, style::MarkupStyle)::AbstractString
        s₁ = style.tag.open.start
        e₁ = style.tag.open.stop
        s₂ = style.tag.close.start
        e₂ = style.tag.close.stop
    
        # get text around the style's tag
        pre = s₁ > 1 ? text[1:s₁ - 1] : ""
        post = e₂ < length(text) ? text[e₂ + 1:end] : ""
        inside = text[e₁+1 : s₂-1]
    
        # start applying styles
        style_init, style_finish = "", ""
        for (attr, value) in toDict(style)
            # BACKGROUND
            if attr == :background
                # if !isnothing(value)
                #     @info value
                #     code = ANSICode(value.color; bg=true, named=(typeof(value) == NamedColor))
                # else
                code = nothing
                # end
            
            # COLOR
            elseif attr == :color
                if !isnothing(value)
                    # @info value string(typeof(value))
                    code = ANSICode(value; bg=false)
                else
                    code = nothing
                end
            
            # MODES
            elseif attr != :tag && value == true
                code = CODES[attr]
            elseif attr != :tag && value == false
                code = reset_code(CODES[attr])
            else
                continue
            end
            
            if !isnothing(code)
                style_init *= code.open
                style_finish *= code.close
            end
        end
        
        text = pre * style_init * style.tag.text * style_finish * post
    end



    """
        apply_style(text::AbstractString)

    Extracts and applies all markup style in a string.
    """
    function apply_style(text::AbstractString; outer::Union{Nothing, MarkupTag}=nothing)::AbstractString
        # @info "Styling" text
        while has_markup(text)
            # get tag
            tag = extract_markup(text; firstonly=true)

            apply_style(tag.text)  # recursivly apply to nested tags
            

            # get style
            style = MarkupStyle(tag)
            text = apply_style(text, style)
        end
        return text
    end

end