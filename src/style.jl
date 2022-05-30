module style
import Parameters: @with_kw

import Term:
    unspace_commas,
    NAMED_MODES,
    has_markup,
    OPEN_TAG_REGEX,
    replace_text,
    get_last_ANSI_code,
    CODES,
    ANSICode,
    tview

import ..color:
    AbstractColor, NamedColor, is_color, is_background, get_color, is_hex_color, hex2rgb

export apply_style

function apply_style(text::String, style::String)
    return apply_style("{" * style * "}" * text * "{/" * style * "}")
end

apply_style(c::Char, style::String) = apply_style(string(c), style)

"""
Check if a string is a mode name
"""
is_mode(string) = string ∈ NAMED_MODES

# ---------------------------------------------------------------------------- #
#                                  MarkupStyle                                 #
# ---------------------------------------------------------------------------- #
"""
    MarkupStyle

Holds information about the style specification set out by a `MarkupTag`.
"""
@with_kw mutable struct MarkupStyle
    default::Bool = false
    bold::Bool = false
    dim::Bool = false
    italic::Bool = false
    underline::Bool = false
    blink::Bool = false
    inverse::Bool = false
    hidden::Bool = false
    striked::Bool = false
    color::Union{Nothing,AbstractColor} = nothing
    background::Union{Nothing,AbstractColor} = nothing
end

"""
    MarkupStyle(tag::MarkupTag)

Builds a MarkupStyle definition from a MarkupTag.
"""
function MarkupStyle(markup)
    codes = split(unspace_commas(markup))

    style = MarkupStyle()
    for code in codes
        if is_mode(code)
            setproperty!(style, Symbol(code), true)
        elseif is_color(code)
            style.color = get_color(code)
        elseif is_background(code)
            style.background = get_color(code; bg = true)
        elseif code != "nothing"
            @debug "Code type not recognized: $code"
        end
    end
    return style
end

# -------------------------------- apply style ------------------------------- #

"""
    get_style_codes(style::MarkupStyle)

Get `ANSICode`s corresponding to a `MarkupStyle`.
"""
function get_style_codes(style::MarkupStyle)
    # start applying styles
    style_init, style_finish = "", ""
    for attr in fieldnames(MarkupStyle)
        value = getfield(style, attr)
        # BACKGROUND
        if attr == :background
            if !isnothing(value)
                code = ANSICode(value; bg = true)
            else
                code = nothing
            end

            # COLOR
        elseif attr == :color
            if !isnothing(value)
                code = ANSICode(value; bg = false)
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
            style_finish *= (occursin(code.close, style_finish) ? "" : code.close)
        end
    end

    return style_init, style_finish
end

"""
    apply_style(text)

Apply style to a piece of text.

Extract markup style information and insert the 
appropriate ANSI codes to style a string.
"""
function apply_style(text)::String
    has_markup(text) || return text

    while has_markup(text)
        # get opening markup tag
        open_match = match(OPEN_TAG_REGEX, text)
        markup = open_match.match[2:(end - 1)]

        # get style codes
        ansi_open, ansi_close = get_style_codes(MarkupStyle(markup))

        # replace markup with ANSI codes
        text = replace_text(
            text,
            max(open_match.offset - 1, 0),
            open_match.offset + length(markup) + 1,
            ansi_open,
        )

        # get closing tag (including [/] or missing close)
        close_rx = r"(?<!\{)\{(?!\{)\/" * markup * r"\}"

        if !occursin(close_rx, text)
            text = text * "{/" * markup * "}"
        end
        close_match = match(close_rx, text)

        # check if there was previous ansi style info
        prev_style = get_last_ANSI_code(tview(text, 1, open_match.offset - 1))
        prev_style = occursin(prev_style, ansi_close) ? "" : prev_style

        # replace close tag
        text = replace_text(
            text,
            close_match.offset - 1,
            close_match.offset + length(markup) + 2,
            ansi_close * prev_style,
        )
    end
    return text
end

end
