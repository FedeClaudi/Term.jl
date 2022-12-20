module Annotations

import Term: fint
import ..Renderables: AbstractRenderable, RenderableText
import ..Segments: Segment
import ..Measures: Measure
import ..Layout: hLine, Spacer

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
    end_index::Int,
    message::String,
)
    lpad = start_index-1
    underscore_width = end_index - start_index+3

    _underscore = " "^(lpad) * hLine(underscore_width, "┬"; pad_txt=false)
    arrow = Spacer(2, lpad+fint(underscore_width/2)-1) * ("│"/"│"/"╰─┤")

    decoration = _underscore / (arrow * ("\n"/" "*message))

    ann = text / decoration
    return Annotation(string(ann))
    
end

function Annotation(text::String, toannotate::String, args...; kwargs...)
    match = findfirst(toannotate, text)
    isnothing(match) && return Annotation(text)
    return Annotation(text, match.start, match.stop, args...; kwargs...)
end




end




