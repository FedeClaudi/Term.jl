module Annotations

import Term: fint, TERM_THEME, cleantext
import ..Renderables: AbstractRenderable, RenderableText, Renderable
import ..Segments: Segment
import ..Measures: Measure, height, width
import ..Layout: hLine, Spacer, vstack, hstack
import ..Panels: Panel
import ..Style: apply_style
import ..Consoles: console_width

export Annotation

struct Annotation <: AbstractRenderable
    segments::Vector
    measure::Measure

    function Annotation(text::String) 
        rt = RenderableText(text)
        return new(rt.segments, rt.measure)
    end
end

"""


A decoration is to make things like:
```
────┬───                              
    │                                 
    │ ╭─────╮
    ╰─│ MSG │
      ╰─────╯
```
"""
struct Decoration
    nun::Int
    position::Int
    underscore::hLine
    panel::Renderable
    style::String
end


function Decoration(num::Int, position::Int, message::String, underscore_width::Int, style::String)
    underscore = hLine(underscore_width, "┬"; pad_txt=false, style="$style dim")

    message = apply_style(message)
    max_w = min(width(message), console_width() - position - 20)

    msg_panel = Panel(RenderableText(message; style=style, width=max_w); fit=true, style="$style dim")
    msg_panel = "{$style dim}│{/$style dim}"/"{$style dim}╰─{/$style dim}" * (Spacer(0, 1)/msg_panel)
    return Decoration(num, position, underscore, msg_panel, style)
end


half(x) = fint(x/2)
make_spaces(widths::Vector{Int}) = map(w -> Spacer(1, w), widths)
join_interleaved(X, Y) = hstack([x*y for (x, y) in zip(X, Y)]...) |> string |> apply_style

function overlay_decorations(decorations::Vector{Decoration})
    n = length(decorations)
    positions = getfield.(decorations, :position)

    # make sure decorations are in order
    sorter = sortperm(positions)
    decorations = decorations[sorter]
    positions = positions[sorter]

    underscores_widths = width.(getfield.(decorations, :underscore))
    underscores_centers = half.(underscores_widths)

    # create the first line with all the underlines
    lines = []
    lpads = map(
        i -> i == 1 ? 
            positions[1] : 
            positions[i] - positions[i-1] - underscores_widths[i-1] + 2,
        1:n
    )
    spaces = make_spaces(lpads)
    push!(lines, join_interleaved(spaces, getfield.(decorations, :underscore)))

    # make a second line with just verticals
    lpads = map(
        i -> i == 1 ? 
            positions[1] + underscores_centers[1] -1 : 
            positions[i] - positions[i-1] - underscores_centers[i-1] + underscores_centers[i] - 1,
        1:n
    )
    spaces = make_spaces(lpads)
    verts = map(d -> "{$(d.style) dim}│{/$(d.style) dim}", decorations)
    push!(lines, join_interleaved(spaces, verts))


    # render additinoal lines with the messages
    decs = Dict([i => decorations[i] for i in 1:n])
    rendering = 1
    while rendering <= n
        # get the pad to the left of the message panel
        lpad = rendering == 1 ? lpads[1] : sum(lpads[1:rendering])+rendering

        # get each line of the message
        for i in 1:decs[rendering].panel.measure.h
            # get the panel segment
            ln = decs[rendering].panel.segments[i]
            pad_size = rendering == 1 ? lpad : lpad - 1
            line = " "^(pad_size) * string(ln)

            # add vertical segments for every other decoration to the side of the message panel
            if rendering < n
                l = width(line)
                for j in rendering+1:n
                    pad_size = decorations[j].position - l + underscores_centers[j] - 1
                    pad_size < 0 && continue
                    space = " "^(pad_size)
                    _style  = decorations[j].style
                    line *= space * "{$_style dim}│{/$_style dim}"
                end
            end

            # add to output
            push!(lines, line)
        end

        # add vertical lines for every remaining decoration
        if rendering < n
            line = " "^(positions[rendering] + underscores_centers[rendering]) 
            push!(lines, line * join_interleaved(spaces[rendering+1:end], verts[rendering+1:end]))
        end

        rendering += 1
    end

    return join(lines, "\n")
end


function Annotation(text::String, annotations::Pair...; kwargs...)
    rawtext = cleantext(text)

    # create decoration objects
    decorations = Decoration[]
    for (i, ann) in enumerate(annotations)
        match = findfirst(ann.first, rawtext)
        isnothing(match) && continue

        # get the message an style
        msg, style = if ann.second isa String
            ann.second, TERM_THEME[].annotation_color
        elseif ann.second isa Tuple
            ann.second
        else
            error("Decoration argument could not be understood: $ann")
        end

        # get the size of the annotation decoration
        underscore_width = match.stop - match.start+3
        push!(decorations, Decoration(i, match.start-1, msg, underscore_width, style))

    end
    # reverse!(decorations)

    decos = overlay_decorations(decorations)
    return Annotation(text/decos)
end




end




