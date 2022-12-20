module Annotations

import Term: fint, TERM_THEME
import ..Renderables: AbstractRenderable, RenderableText
import ..Segments: Segment
import ..Measures: Measure
import ..Layout: hLine, Spacer
import ..Panels: Panel

export Annotation

struct Annotation <: AbstractRenderable
    segments::Vector
    measure::Measure

    function Annotation(text::String) 
        rt = RenderableText(text)
        return new(rt.segments, rt.measure)
    end
end





function Annotation(
    text::String,
    start_index::Int,
    stop_index::Int,
    message::String,
)   
    style = TERM_THEME[].annotation_color
    lpad = start_index-1
    underscore_width = stop_index - start_index+3

    _underscore = " "^(lpad) * hLine(underscore_width, "┬"; pad_txt=false, style="$style dim")

    v, h = "{$style dim}│{/$style dim}", "{$style dim}╰─{/$style dim}"
    arrow = Spacer(2, lpad+fint(underscore_width/2)-1) * (v / v / h)

    text = text[1:start_index-1] * "{$(style)}" * text[start_index:stop_index] * "{/$(style)}" * text[stop_index+1:end]
    
    msg_panel = Panel(message; fit=true, style="$style dim")
    decoration = _underscore / (arrow * ("\n"/msg_panel))

    ann = text / decoration
    return Annotation(string(ann))
    
end

function Annotation(text::String, toannotate::String, args...; kwargs...)
    match = findfirst(toannotate, text)
    isnothing(match) && return Annotation(text)
    return Annotation(text, match.start, match.stop, args...; kwargs...)
end




end




