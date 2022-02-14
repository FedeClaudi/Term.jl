using Revise
Revise.revise()

using Term
import Term: Segment
import Term.style: MarkupStyle, toDict
import Term: CODES, ANSICode
import Term.color: NamedColor

# ENV["JULIA_DEBUG"] = "all"

test = "[red bold underline on_black]RED BOLD UNDERLINE[/] fsdfisd [on_blue dim]dfoisdfs[/on_blue dim]"


seg = Segment(test)

styles = seg.styles



function apply_style(text::AbstractString, style::MarkupStyle)
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
        if attr == :background
            code = ANSICode(value.color; bg=true, named=(typeof(value) == NamedColor))

        elseif attr == :color
            code = ANSICode(value.color; bg=false, named=(typeof(value) == NamedColor))

        elseif attr != :tag && value == true
            code = CODES[attr]
        else
            continue
        end

        style_init *= code.open
        style_finish *= code.close
    end

    @info "ANSI" style_init style_finish

    text = pre * style_init * inside * style_finish * post
end


function apply_style(text::AbstractString, styles::Vector)
    for style in styles
        text = apply_style(text, style)
    end
    return text
end

tt = apply_style(test, styles)
println(test)
println(tt)