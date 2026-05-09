"""
    @style "text" style1 style2...

Applies a sequence of styles to a piece of text, such that

    println(@style "my text" bold green underline)

will print `my text` as bold, green and underlined
"""
macro style(text, styles...)
    markup = join(styles, " ")
    return quote
        local txt = $(esc(text))
        with_markup = "{$($markup)}$txt{/$($markup)}"
        apply_style(with_markup)
    end
end

# ------------------------- macros generating macros ------------------------- #
"""
Macro to create macros such as `@green` which colors text accordingly
"""
macro make_color_macro(color)
    return quote
        macro $(esc(color))(text)
            color_str = $(string(color))
            return quote
                local txt = $(esc(text))
                code = ANSICode(get_color($color_str); bg = false)
                styled = apply_style(txt)
                string(code.open * styled * code.close)
            end
        end
    end
end

"""
Macro to create macros such as `@underline` which styles text accordingly.
"""
macro make_mode_macro(mode)
    return quote
        macro $(esc(mode))(text)
            mode_str = $(string(mode))
            return quote
                local txt = $(esc(text))
                code = CODES[Symbol($mode_str)]
                styled = apply_style(txt)
                code.open * styled * code.close
            end
        end
    end
end

# ---------------------------------- colors ---------------------------------- #
@make_color_macro black
@make_color_macro red
@make_color_macro green
@make_color_macro yellow
@make_color_macro blue
@make_color_macro magenta
@make_color_macro cyan
@make_color_macro white
@make_color_macro default

# ----------------------------------- modes ---------------------------------- #
@make_mode_macro bold
@make_mode_macro dim
@make_mode_macro italic
@make_mode_macro underline
