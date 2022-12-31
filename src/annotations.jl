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

# ---------------------------------------------------------------------------- #
#                                  DECORATION                                  #
# ---------------------------------------------------------------------------- #

"""
struct Decoration
    nun::Int
    position::Int
    underscore::hLine
    panel::Renderable
    style::String
end

A decoration storing a message to anotate a piece of text.
`Decoration`s are used by `Annotation` to annotate text.

A `Decoration` looks something like this when rendered.
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

"""
    Decoration(num::Int, position::Int, message::String, underscore_width::Int, style::String)

Construct a `Decoration`. When preparing the `Panel` with the message, the `message` text
gets resized if its too large (based on `position` and `console_width`).

## Arguments
- `num` number of decoration (for `Annotation` with multiple decorations)
- `position` position of the decoration start in the text (position of the start of the underscore)
- `message` text going inside the message box
- `underscore_width`: the width of the underscore line. 
- `style`: color/style information
"""
function Decoration(
    num::Int,
    position::Int,
    message::String,
    underscore_width::Int,
    style::String,
)
    # create hLine underscore
    underscore = hLine(underscore_width, "┬"; pad_txt = false, style = "$style dim")

    # get the width of the text, see if it needs to be adjusted
    max_w = min(width(message), console_width() - position - 30)

    # create `Panel` and add the end of an "arrow" to the side.
    msg_panel = Panel(
        RenderableText(message; style = style, width = max_w);
        fit = true,
        style = "$style dim",
    )
    msg_panel =
        "{$style dim}│{/$style dim}" / "{$style dim}╰─{/$style dim}" *
        (Spacer(0, 1) / msg_panel)
    return Decoration(num, position, underscore, msg_panel, style)
end

""" halve and round a number """
half(x) = fint(x / 2)

""" Make a vector of `Spacer` objects of given widths"""
make_spaces(widths::Vector{Int})::Vector{Spacer} =
    collect(map(w -> Spacer(1, max(0, w)), widths))

""" hstack interleaved elements x ∈ X, y ∈ Y """
join_interleaved(X, Y) = hstack([x * y for (x, y) in zip(X, Y)]...) |> string |> apply_style

"""
    overlay_decorations(decorations::Vector{Decoration})

Overlayed rendering of multiple `Decoration` object.
Given multiple decorations, create a visualization like:

```
Panel(content; fit=true)                                                                 
──┬── ───┬───  ────┬───                                                                  
  │      │         │                                                                     
  │ ╭─────────────────────────────────╮                                                  
  ╰─│  this is the panel constructor  │                                                  
    ╰─────────────────────────────────╯                                                  
         │         │                                                                     
         │ ╭───────────────────────────────────────────╮                                 
         ╰─│  here you put what goes inside the panel  │                                 
           ╰───────────────────────────────────────────╯                                 
                   │                                                                     
                   │ ╭──────────────────────────────────────────────────────────────────╮
                   ╰─│  Setting this as `true` adjusts the panel's width to fit         │
                     │  `content`. Otherwise `Panel` will have a fixed width            │
                     ╰──────────────────────────────────────────────────────────────────╯
```

Note: we need all the underscores, the vertical lines to be in the right place
and for the `Panel` with heach message to be over the lines of the following
decorations. Spacing should be accounted to make sure all messages are visible. 

Note: this function is quite long and nasty, but it seems to work well.
"""
function overlay_decorations(decorations::Vector{Decoration})
    n = length(decorations)
    positions = getfield.(decorations, :position)

    # make sure decorations are in order based on position
    sorter = sortperm(positions)
    decorations = decorations[sorter]
    positions = positions[sorter]

    # get some info
    underscores_widths = width.(getfield.(decorations, :underscore))
    underscores_centers = half.(underscores_widths)

    # create the first line with all the underlines
    lines = []
    lpads = map(
        i ->
            i == 1 ? positions[1] :
            positions[i] - positions[i - 1] - underscores_widths[i - 1] + 2,
        1:n,
    )

    spaces = make_spaces(lpads)
    push!(lines, join_interleaved(spaces, getfield.(decorations, :underscore)))

    # make a second line with just verticals
    lpads = map(
        i ->
            i == 1 ? positions[1] + underscores_centers[1] - 1 :
            positions[i] - positions[i - 1] - underscores_centers[i - 1] +
            underscores_centers[i] - 1,
        1:n,
    )
    spaces = make_spaces(lpads)
    verts = map(d -> "{$(d.style) dim}│{/$(d.style) dim}", decorations)
    push!(lines, join_interleaved(spaces, verts))

    # render additional lines with their messages
    decs = Dict([i => decorations[i] for i in 1:n])
    rendering = 1
    while rendering <= n
        # get the pad to the left of the message panel
        lpad = rendering == 1 ? lpads[1] : sum(lpads[1:rendering]) + rendering

        # get each line of the message
        for i in 1:(decs[rendering].panel.measure.h)
            # get the panel segment & add space to put it in the right place
            ln = decs[rendering].panel.segments[i]
            pad_size = rendering == 1 ? lpad : lpad - 1
            line = " "^(pad_size) * string(ln)

            # add vertical segments for every other decoration to the side of the message panel
            if rendering < n
                for j in (rendering + 1):n
                    l = width(line)
                    pad_size = decorations[j].position - l + underscores_centers[j] - 1
                    pad_size < 0 && continue
                    space = " "^(pad_size)
                    _style = decorations[j].style
                    line *= space * "{$_style dim}│{/$_style dim}"
                end
            end

            # add to output
            push!(lines, line)
        end

        # add a line with the vertical elements of each decoration left to render
        if rendering < n
            line = " "^(positions[rendering] + underscores_centers[rendering])
            push!(
                lines,
                line *
                join_interleaved(spaces[(rendering + 1):end], verts[(rendering + 1):end]),
            )
        end

        rendering += 1
    end

    return join(lines, "\n")
end

# ---------------------------------------------------------------------------- #
#                                  ANNOTATION                                  #
# ---------------------------------------------------------------------------- #

"""
    struct  Annotation <: AbstractRenderable
        segments::Vector
        measure::Measure
    end

Represents a bit of text with some additional annotations. 
Annotations are additional messages that get printed below 
the main piece of text.

## Example
```julia
Annotation("This is the text", "text"=>"this is an annotation")
````
gives
```
This is the text                           
            ──┬─                           
              │                            
              │ ╭─────────────────────────╮
              ╰─│  this is an annotation  │
                ╰─────────────────────────╯
```

---
This bit:
```
──┬─                           
  │                            
  │ ╭─────────────────────────╮
  ╰─│  this is an annotation  │
    ╰─────────────────────────╯
```
is called a `Decoration`. 

A piece of text can have multiple decorations if multiple pares are 
passed in the function call above. 
"""
struct Annotation <: AbstractRenderable
    segments::Vector
    measure::Measure

    function Annotation(text::String)
        rt = RenderableText(text)
        return new(rt.segments, rt.measure)
    end
end

"""
    Annotation(text::String, annotations::Pair...; kwargs...)

Construct an `Annotation`.

The argument `annotations` is a set of `Pair`s denoting which parts
of `text` gets annotated, with what, and what style information each annotation
should have. These pairas can be of the form `String=>String` if no style information
is passed, otherwise `String=>(String, String)` where the first `String` in the 
parentheses is the annotation message and the second the style info. The first `String`
in the `Pair` should be a substring of `text` to denote where the annotation occurs.
"""
function Annotation(text::String, annotations::Pair...; kwargs...)
    @assert width(text) < console_width() && height(text) == 1 "Annotation can only annotate a single line, small enough to fit in the screen."
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
        underscore_width = match.stop - match.start + 3
        push!(decorations, Decoration(i, match.start - 1, msg, underscore_width, style))
    end
    # reverse!(decorations)

    decos = overlay_decorations(decorations)
    return Annotation(text / decos)
end

end
