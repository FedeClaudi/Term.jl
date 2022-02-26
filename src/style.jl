module style
    include("__text_utils.jl")
    include("_ansi.jl")
    import Parameters: @with_kw

    import ..markup: MarkupTag, extract_markup, has_markup
    import ..color: AbstractColor, NamedColor, is_color, is_background, get_color, is_hex_color, hex2rgb

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
        default::Bool       = false
        bold::Bool          = false
        dim::Bool           = false
        italic::Bool        = false
        underline::Bool     = false
        blink::Bool         = false
        inverse::Bool       = false
        hidden::Bool        = false
        striked::Bool       = false

        color::Union{Nothing, AbstractColor}            = nothing
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
                @warn "Code type not recognized: $code" tag tag.markup
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

    function get_style_codes(style::MarkupStyle)
        # start applying styles
        style_init, style_finish = "", ""
        for (attr, value) in toDict(style)
            # BACKGROUND
            if attr == :background
                if !isnothing(value)
                    code = ANSICode(value; bg=true)
                else
                    code = nothing
                end
            
            # COLOR
            elseif attr == :color
                if !isnothing(value)
                    code = ANSICode(value; bg=false)
                else
                    code = nothing
                end
            
            # MODES
            elseif attr != :tag && value == true
                code = CODES[attr]

                
            else
                if value != false && attr != :tag
                    @debug "Attr/value not recognized or not set" attr value
                end
                continue
            end
            
            if !isnothing(code)
                style_init *= code.open
                style_finish *= code.close
            end
        end

        return style_init, style_finish
    end

    function apply_style(text::AbstractString, style::MarkupStyle)::AbstractString
        style_init, style_finish = get_style_codes(style)

        text = style_init * text * style_finish
    end


    """
        apply_style(text::AbstractString, tag::MarkupTag)::AbstractString

    Applies the style of a markup tag and it's nested tags
    """
    function apply_style(text::AbstractString, tag::MarkupTag)::AbstractString
        style = MarkupStyle(tag)
        style_init, style_finish = get_style_codes(style)

        # if no inner tags, just style the text
        if length(tag.inner_tags) == 0
            return apply_style(tag.text, style)
        end

        # apply inner tags
        for inner in tag.inner_tags
            # @info "style inner" inner inner.markup tag.text text
            inner_text = apply_style(inner.text, inner)

            text = replace(
                        tag.text, 
                        "[$(inner.open.markup)]$(inner.text)[$(inner.close.markup)]" => 
                        "$(inner_text)$(style_init)"
                    )
        end

        # apply outer tag
        text = apply_style(text, style)

        return text
    end

    """
        apply_style(text::AbstractString)

    Extracts and applies all markup style in a string.
    """
    function apply_style(text::AbstractString;)::AbstractString
        @info "APPLYING STYLE" text
        while has_markup(text)
            tag = extract_markup(text; firstonly=true)
            @info "tag" tag tag.markup

            pre = text[1:tag.open.start - 1]
            post = text[tag.close.stop+1:end]

            text = pre * apply_style(text, tag) * post
            @info "     styled: " text
        end
        return text
    end

end