module Panels

import Term:
    reshape_text, join_lines, fillin, str_trunc, ltrim_str, default_width, remove_ansi

import ..Renderables: AbstractRenderable, RenderablesUnion, Renderable, RenderableText
import ..Layout: pad, vstack, Padding, lvstack
import ..Style: apply_style
import ..Segments: Segment
import ..Measures: Measure
import ..Measures: height as get_height
import ..Measures: width as get_width
import ..Consoles: console_width, console_height
using ..Boxes

export Panel, TextBox

abstract type AbstractPanel <: AbstractRenderable end

# ---------------------------------------------------------------------------- #
#                                     PANEL                                    #
# ---------------------------------------------------------------------------- #
"""
    Panel

`Renderable` with a panel surrounding some content:

```
    ╭──────────╮
    │ my panel │
    ╰──────────╯
```
"""
mutable struct Panel <: AbstractPanel
    segments::Vector
    measure::Measure

    function Panel(x1, x2; kwargs...)
        # this is necessary to handle the special case in which 2 objs are passed
        # but they are not segments/measure
        return if x1 isa Vector && x2 isa Measure
            new(x1, x2)
        else
            Panel(vstack(x1, x2); kwargs...)
        end
    end
end

Base.size(p::Panel) = size(p.measure)

"""
---

    Panel(; 
        fit::Bool = false,
        height::Int = 2,
        width::Int = $(default_width()),
        padding::Union{Vector,Padding,NTuple} = Padding(0, 0, 0, 0),
        kwargs...,  
    )

Construct a `Panel` with no content.


### Examples
```
julia> Panel(height=5, width=10)
╭────────╮
│        │
│        │
│        │
╰────────╯

julia> Panel(height=3, width=5)
╭───╮
│   │
╰───╯
```
"""
function Panel(;
    fit::Bool = false,
    height::Int = 2,
    width::Int = default_width(),
    padding::Union{Vector,Padding,NTuple} = Padding(0, 0, 0, 0),
    kwargs...,
)
    # get panel measure
    panel_measure = if fit
        # hardcoded size of empty 'fitted' panel
        Measure(2, 3)
    else
        Measure(height, width)
    end

    # get empty content measure
    content = ""
    content_measure = Measure(0, 0)

    # get padding
    padding = padding isa Padding ? padding : Padding(padding...)

    # make panel
    return Panel(
        content;
        fit = fit,
        panel_measure = panel_measure,
        content_measure = content_measure,
        Δw = padding.left + padding.right + 2,
        Δh = padding.top + padding.bottom,
        height = height,
        width = width,
        padding = padding,
        kwargs...,
    )
end

"""
---
    Panel(
        content::Union{AbstractString,AbstractRenderable};
        fit::Bool = true,
        padding::Union{Padding,NTuple} = Padding(2, 2, 0, 0),
        kwargs...,
    )

Construct a `Panel` around an `AbstractRenderable` or `AbstractString`.

This is the main Panel-creating function, it dispatches to other methods based
on the value of `fit` to either fith the `Panel` to its content or vice versa.

`kwargs` can be used to set various aspects of the `Panel`'s appearance like
the presence and style of titles, box type etc... see [render](@ref) below.
"""
function Panel(
    content::Union{AbstractString,AbstractRenderable};
    fit::Bool = true,
    padding::Union{Padding,NTuple} = Padding(2, 2, 0, 0),
    width::Int = default_width(),
    kwargs...,
)
    padding = padding isa Padding ? padding : Padding(padding...)

    # estimate content and panel size 
    content_width = content isa AbstractString ? textwidth(content) : content.measure.w
    panel_width = if fit
        content_width + padding.left + padding.right + 2
    else
        width
    end

    # if too large, set fit=false
    fit && (fit = panel_width <= console_width())
    fit && (width = panel_width)

    # @info "Ready to make panel" content_width panel_width width fit
    return Panel(content, Val(fit), padding; width = width, kwargs...)
end

"""
---

    Panel(
        content::Union{AbstractString,AbstractRenderable},
        ::Val{true},
        padding::Padding;
        height::Union{Nothing,Int} = nothing,
        width::Union{Nothing,Int} = nothing,
        kwargs...,
        )

Construct a `Panel` fitting the content's width.

!!! warning
    If the content is larger than the console terminal's width, it will get trimmed to avoid overflow.
"""
function Panel(
    content::Union{AbstractString,AbstractRenderable},
    ::Val{true},
    padding::Padding;
    height::Union{Nothing,Int} = nothing,
    width::Int,
    background::Union{Nothing,String} = nothing,
    kwargs...,
)
    Δw = padding.left + padding.right + 2
    Δh = padding.top + padding.bottom

    # create content
    content =
        content isa AbstractRenderable ? content :
        RenderableText(content, width = width - Δw - 2, background = background)

    # estimate panel size
    panel_measure = Measure(
        max(something(height, 0), content.measure.h + padding.top + padding.bottom + 2),
        max(width, content.measure.w + padding.left + padding.right + 2),
    )

    return render(
        content;
        panel_measure = panel_measure,
        content_measure = content.measure,
        Δw = Δw,
        Δh = Δh,
        padding = padding,
        background = background,
        kwargs...,
    )
end

"""
---
    Panel(
        content::Union{AbstractString,AbstractRenderable},
        ::Val{false},
        padding::Padding;
        height::Union{Nothing,Int} = nothing,
        width::Int = $(default_width()),
        kwargs...,
    )

Construct a `Panel` fitting content to it.

!!! tip
    Content that is **too large** to fit in the given width will be trimmed. 
    To avoid trimming, set ```fit=true``` when calling panel. 

"""
function Panel(
    content::Union{AbstractString,AbstractRenderable},
    ::Val{false},
    padding::Padding;
    height::Union{Nothing,Int} = nothing,
    width::Int = default_width(),
    background::Union{Nothing,String} = nothing,
    kwargs...,
)
    Δw = padding.left + padding.right + 2
    Δh = padding.top + padding.bottom

    # if the content is too large, resize it to fit the panel's width.
    get_width(content) > width - Δw + 1 &&
        (content = trim_renderable(content, width - Δw - 1))

    # get panel height
    content =
        content isa AbstractRenderable ? content :
        RenderableText(content, width = width - Δw - 1, background = background)
    height = something(height, content.measure.h + Δh + 2)
    panel_measure = Measure(height, width)

    # if the content is too tall, exclude some lines
    if content.measure.h > height - Δh - 1
        content = if content.measure.h - height - Δh - 2 > 0
            segments = [
                content.segments[1:(height - Δh - 3)]...
                Segment("... content omitted ...", "dim")
            ]
            Renderable(segments, Measure(segments))
        else
            RenderableText("")
        end
    end

    return render(
        content;
        panel_measure = panel_measure,
        content_measure = content.measure,
        Δw = Δw,
        Δh = Δh,
        padding = padding,
        background = background,
        kwargs...,
    )
end

"""
    Panel(renderables; kwargs...)

`Panel` constructor for creating a panel out of multiple renderables at once.
"""
Panel(renderables::Vector{RenderablesUnion}; kwargs...) =
    Panel(vstack(renderables...); kwargs...)

Panel(texts::Vector{AbstractString}; kwargs...) = Panel(join_lines(texts); kwargs...)

Panel(renderables...; kwargs...) = Panel(vstack(renderables...); kwargs...)

# ---------------------------------- render ---------------------------------- #

"""
    render(
        content;
        box::Symbol = :ROUNDED,
        style::String = "default",
        title::Union{String,Nothing} = nothing,
        title_style::Union{Nothing,String} = nothing,
        title_justify::Symbol = :left,
        subtitle::Union{String,Nothing} = nothing,
        subtitle_style::Union{Nothing,String} = nothing,
        subtitle_justify::Symbol = :left,
        justify::Symbol = :left,
        panel_measure::Measure,
        content_measure::Measure,
        Δw::Int,
        Δh::Int,
        padding::Padding,
    )::Panel

Construct a `Panel`'s content.
"""
function render(
    content;
    box::Symbol = :ROUNDED,
    style::String = "default",
    title::Union{String,Nothing} = nothing,
    title_style::Union{Nothing,String} = nothing,
    title_justify::Symbol = :left,
    subtitle::Union{String,Nothing} = nothing,
    subtitle_style::Union{Nothing,String} = nothing,
    subtitle_justify::Symbol = :left,
    justify::Symbol = :left,
    panel_measure::Measure,
    content_measure::Measure,
    Δw::Int,
    Δh::Int,
    padding::Padding,
    background = nothing,
    kwargs...,
)::Panel
    # @info "calling render" panel_measure content_measure

    # create top/bottom rows with titles
    box = eval(box)  # get box object from symbol
    top = get_title_row(
        :top,
        box,
        title;
        width = panel_measure.w,
        style = style,
        title_style = title_style,
        justify = title_justify,
    )

    bottom = get_title_row(
        :bottom,
        box,
        subtitle;
        width = panel_measure.w,
        style = style,
        title_style = subtitle_style,
        justify = subtitle_justify,
    )

    # get left/right vertical lines
    σ(s) = apply_style("\e[0m{" * style * "}" * s * "{/" * style * "}")
    left, right = σ(box.mid.left), σ(box.mid.right)

    # get an empty padding line
    empty = if isnothing(background)
        [Segment(left * " "^(panel_measure.w - 2) * right;)]
    else
        [
            Segment(
                left *
                "{$background}" *
                " "^(panel_measure.w - 2) *
                "{/$background}" *
                right;
            ),
        ]
    end
    # @info "rendering" panel_measure Δw

    # add lines with content fn
    function makecontent_line(cline)::Segment
        line = pad(apply_style(cline), panel_measure.w - Δw, justify; bg = background)
        line = pad(line, padding.left, padding.right; bg = background)

        # make line
        return Segment(left * line * right)
    end

    # check if we need extra lines at the bottom to reach target height
    n_extra = if content_measure.h < panel_measure.h - Δh - 2
        panel_measure.h - content_measure.h - Δh - 2
    else
        0
    end

    # create segments
    initial_segments::Vector{Segment} = [
        top,                                        # top border
        repeat(empty, padding.top)...,              # top padding
    ]

    # content
    content_sgs::Vector{Segment} =
        content.measure.w > 0 ? map(s -> makecontent_line(s.text), content.segments) : []

    final_segments::Vector{Segment} = [
        repeat(empty, n_extra)...,                  # lines to reach target height
        repeat(empty, padding.bottom)...,           # bottom padding
        bottom * "\e[0m",                           # bottom border
    ]

    segments = vcat(initial_segments, content_sgs, final_segments)
    return Panel(segments, panel_measure)
end

# ---------------------------------------------------------------------------- #
#                                    TextBox                                   #
# ---------------------------------------------------------------------------- #

TextBox(args...; kwargs...) = Panel(args...; box = get(kwargs, :box, :NONE), kwargs...)

# ---------------------------------------------------------------------------- #
#                                     MISC.                                    #
# ---------------------------------------------------------------------------- #

"""
    trim_renderable(ren::Union{String, AbstractRenderable}, width::Int)

Trim a string or renderable to a max width.
"""
function trim_renderable(ren::AbstractRenderable, width::Int)
    text = getfield.(ren.segments, :text)

    return if ren isa RenderableText
        reshape_text.(text, width) |> lvstack
    else
        # @info "trimming ren" ren.measure width text
        segs = map(
            s -> get_width(s) > width ? pad(str_trunc(s, width), width, :left) : s,
            text,
        )
        lvstack(segs)
    end
end

trim_renderable(ren::AbstractString, width::Int) = begin
    reshape_text(ren, width)
end
end
