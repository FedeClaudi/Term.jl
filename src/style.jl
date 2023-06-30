module Style

import Parameters: @with_kw

import Term:
    unspace_commas,
    NAMED_MODES,
    has_markup,
    OPEN_TAG_REGEX,
    replace_text,
    CODES,
    ANSICode,
    tview,
    do_by_line,
    ANSI_REGEX

import ..Colors:
    AbstractColor, NamedColor, is_color, is_background, get_color, is_hex_color, hex2rgb

export apply_style

apply_style(text::String, style::String) =
    if occursin('\n', text)
        do_by_line(ln -> apply_style(ln, style), text)
    else
        apply_style("{" * style * "}" * text * "{/" * style * "}")
    end

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
    style = MarkupStyle()
    for code in split(unspace_commas(markup))
        if is_mode(code)
            setproperty!(style, Symbol(code), true)
        elseif is_color(code)
            style.color = get_color(code)
        elseif is_background(code)
            style.background = get_color(code; bg = true)
            # elseif code != "nothing"
            #     @debug "Code type not recognized: $code"
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
        if attr ≡ :background
            code = isnothing(value) ? nothing : ANSICode(value; bg = true)
        elseif attr ≡ :color
            if !isnothing(value)
                try
                    code = ANSICode(value; bg = false)
                catch
                    continue
                end
            else
                code = nothing
            end
        elseif attr != :tag && value == true  # MODES
            code = CODES[attr]
        else
            # if value != false && attr != :tag
            #     @debug "Attr/value not recognized or not set" attr value
            # end
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

When multiple, nested color tags are present, like in"
    "{red} abcd {green} asd {/green} eadsa {/red}"
extra care should be put to ensure that when `green` is closed
the text is rendered as red. To this end, this function
keeps track of the last color style information and where it occurred in the input
text. If the current markup tag is nested in the previous, it changes, for example
    "{/green}"
to
    "{/green}{red}".
The same in parallel has to be done for background colors. 

By default, "orphaned" tags (i.e. open/close markup tags without the corresponding
tag) are removed from the string. Use `leave_orphan_tags` to change this behavior.
"""
function apply_style(text; leave_orphan_tags = false)::String
    has_markup(text) || return text

    previous_color = (0, length(text), MarkupStyle("default"))
    previous_background = (0, length(text), MarkupStyle("default"))
    while has_markup(text)
        # get opening markup tag
        open_match = match(OPEN_TAG_REGEX, text)
        markup = open_match.match[2:(end - 1)]

        # get style codes
        ms = MarkupStyle(markup)
        ansi_open, ansi_close = get_style_codes(ms)

        # insert open tag
        if ansi_open == "" && ansi_close == "" && leave_orphan_tags
            # found an invalid tag (e.g. {string}). Leave it but edit it to avoid getting stuck in this lookup
            # replace markup with ANSI codes
            text = replace_text(
                text,
                max(open_match.offset - 1, 0),
                open_match.offset + length(markup) + 1,
                "{{" * markup * "}}",
            )
        else
            # replace markup with ANSI codes
            text = replace_text(
                text,
                max(open_match.offset - 1, 0),
                open_match.offset + length(markup) + 1,
                ansi_open,
            )
        end

        # get closing tag (including [/] or missing close)
        close_rx = r"(?<!\{)\{(?!\{)\/" * markup * r"\}"
        if !occursin(close_rx, text)
            text = text * "{/" * markup * "}"
        end
        close_match = match(close_rx, text)

        # if previous style had color and we're nested, use color info
        if open_match.offset > previous_color[1] &&
           close_match.offset < previous_color[2] &&
           !isnothing(previous_color[3].color)
            col_prev_ansi_open, _ = get_style_codes(previous_color[3])
            ansi_close = ansi_close * col_prev_ansi_open
        end

        # and for background
        if open_match.offset > previous_background[1] &&
           close_match.offset < previous_background[2] &&
           !isnothing(previous_background[3].background)
            bg_prev_ansi_open, _ = get_style_codes(previous_background[3])
            ansi_close = ansi_close * bg_prev_ansi_open
        end

        # replace close tag
        text = replace_text(
            text,
            close_match.offset - 1,
            close_match.offset + length(markup) + 2,
            ansi_close,
        )

        # store style info
        isnothing(ms.color) || (
            previous_color = (
                max(open_match.offset - 1, 0),
                close_match.offset + length(markup) + 2,
                ms,
            )
        )

        isnothing(ms.background) || (
            previous_background = (
                max(open_match.offset - 1, 0),
                close_match.offset + length(markup) + 2,
                ms,
            )
        )
    end
    return text
end

end
