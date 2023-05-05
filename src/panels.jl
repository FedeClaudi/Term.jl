module Panels

import Term:
    join_lines, ltrim_str, default_width, remove_ansi, get_bg_color, textlen, TERM_THEME

import ..Renderables: AbstractRenderable, RenderablesUnion, Renderable, RenderableText
import ..Layout: pad, vstack, Padding, lvstack
import ..Style: apply_style
import ..Segments: Segment
import ..Measures: Measure
import ..Measures: height as get_height
import ..Measures: width as get_width
import ..Consoles: console_width, console_height
using ..Boxes

export Panel, TextBox, @nested_panels

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

---

When constructing a Panel, several keyword arguments can be used to set
its appearance:
- box::Symbol sets the `Box` type for the Panel's border
- style::String  sets the box's style (e.g., color)
- title::Union{String,Nothing}  sets the Panel's title
- title_style::Union{Nothing,String} sets the title's style
- title_justify::Symbol     sets the location of the title
- subtitle::Union{String,Nothing}  sets the Panel's subtitle
- subtitle_style::Union{Nothing,String}  sets the subtitle's style
- subtitle_justify::Symbol  sets the location of the subtitle
- justify::Symbol sets text's alignment (:left, :rigth, :center, :justify)
"""
mutable struct Panel <: AbstractPanel
    segments::Vector
    measure::Measure

    """
        Panel(x1, x2; kwargs...)

    Catch construction with exactly two items passed
    """
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
        Measure(height - 1, width)
    end

    # get empty content measure
    content = ""
    content_measure = Measure(0, 0)

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
        padding = Padding(padding),
        kwargs...,
    )
end

"""
    Panel(
        content::Union{AbstractString,AbstractRenderable};
        fit::Bool = false,
        padding::Union{Nothing,Padding,NTuple} = nothing,
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
    fit::Bool = false,
    padding::Union{Nothing,Padding,NTuple} = nothing,
    width::Int = default_width(),
    kwargs...,
)
    padding = if isnothing(padding)
        if get(kwargs, :style, "default") == "hidden"
            Padding(0, 0, 0, 0)
        else
            Padding(2, 2, 0, 0)
        end
    else
        Padding(padding)
    end

    # estimate content and panel size 
    content_width = content isa AbstractString ? Measure(content).w : content.measure.w
    panel_width = if fit
        content_width + padding.left + padding.right + 2
    else
        width
    end

    # if too large, set fit=false
    fit = if fit
        (!isa(content, AbstractString) ? panel_width <= console_width() : true)
    else
        false
    end
    width = fit ? min(panel_width, console_width()) : width

    # @debug "Ready to make panel" content content_width panel_width width console_width() fit
    return Panel(content, Val(fit), padding; width = width, kwargs...)
end

"""
    content_as_renderable(content, width, Δw, justify)

Convert any input content to a renderable
"""
content_as_renderable(
    content,
    width::Int,
    Δw::Int,
    justify::Symbol,
    background::Union{String,Nothing},
)::RenderableText =
    RenderableText(content; width = width - Δw, background = background, justify = justify)

"""

    Panel(
        content::Union{AbstractString,AbstractRenderable},
        ::Val{true},
        padding::Padding;
        height::Union{Nothing,Int} = nothing,
        width::Union{Nothing,Int} = nothing,
        trim::Bool = true,
        kwargs...,
    )

Construct a `Panel` fitting the content's width.

!!! warning
    If the content is larger than the console terminal's width, it will get trimmed to avoid overflow, unless `trim=false` is given.
"""
function Panel(
    content::Union{AbstractString,AbstractRenderable},
    ::Val{true},
    padding::Padding;
    height::Union{Nothing,Int} = nothing,
    width::Int,
    background::Union{Nothing,String} = nothing,
    justify::Symbol = :left,
    kwargs...,
)
    Δw = padding.left + padding.right + 2
    Δh = padding.top + padding.bottom

    # create content
    # @info "panel fit" width height Δw Δh background
    content = content_as_renderable(content, width, Δw, justify, background)

    # estimate panel size
    panel_measure = Measure(
        max(something(height, 0), content.measure.h + padding.top + padding.bottom + 2),
        max(width, content.measure.w + padding.left + padding.right + 2),
    )

    # @debug "Creating fitted panel" content.measure panel_measure content
    return render(
        content;
        panel_measure = panel_measure,
        content_measure = content.measure,
        Δw = Δw,
        Δh = Δh,
        padding = padding,
        background = background,
        justify = justify,
        kwargs...,
    )
end

"""
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
    justify::Symbol = :left,
    kwargs...,
)
    Δw = padding.left + padding.right + 2
    Δh = padding.top + padding.bottom

    # if the content is too large, resize it to fit the panel's width.
    content = content_as_renderable(content, width, Δw, justify, background)
    height = something(height, content.measure.h + Δh + 2)
    panel_measure = Measure(height, width)
    # @info "panel nofit" width  Δw Δh height panel_measure background content.measure

    # if the content is too tall, exclude some lines
    if content.measure.h > height - Δh - 2
        lines_to_drop = content.measure.h - height + Δh + 3
        omit_msg = RenderableText(
            "... content omitted ...",
            style = "dim",
            width = content.measure.w,
            justify = :center,
            background = background,
        )

        segments = if lines_to_drop < content.measure.h
            Segment[
                content.segments[1:(end - lines_to_drop)]...
                omit_msg.segments[1]
            ]
        else
            # [omit_msg.segments[1]]
            [content.segments[1]]
        end
        content = Renderable(segments, Measure(segments))
    end

    # @debug "creating not fitted panel" content.measure panel_measure width Δw 
    return render(
        content;
        panel_measure = panel_measure,
        content_measure = content.measure,
        Δw = Δw,
        Δh = Δh,
        padding = padding,
        background = background,
        justify = justify,
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
Panel(ren::Vector; kwargs...) = Panel(vstack(ren); kwargs...)
Panel(ren, renderables...; kwargs...) = Panel(vstack(ren, renderables...); kwargs...)

# ---------------------------------- render ---------------------------------- #

"""
    makecontent_line(cline, panel_measure, justify, background, padding, left, right)::Segment

Create a Panel's content line.
"""
function makecontent_line(
    cline::Segment,
    panel_measure::Measure,
    justify::Symbol,
    background::Union{Nothing,String},
    padding::Padding,
    left::String,
    right::String,
    Δw::Int,
)::Segment
    line = pad(cline, panel_measure.w - Δw, justify, ; bg = background).text
    line = pad(line, padding.left, padding.right; bg = background)
    return Segment(typeof(cline.text)(left * line * right))
end

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
        text_justify::Bool=false,
        panel_measure::Measure,
        content_measure::Measure,
        Δw::Int,
        Δh::Int,
        padding::Padding,
    )::Panel

Construct a `Panel`'s content.
"""
function render(
    content::Union{Renderable,RenderableText};
    box::Symbol = TERM_THEME[].box,
    style::String = TERM_THEME[].line,
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
    background::Union{Nothing,String} = nothing,
    kwargs...,
)::Panel
    background = get_bg_color(background)
    # @info "calling render" content content_measure background

    # create top/bottom rows with titles
    box = BOXES[box]  # get box object from symbol
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
    σ(s) = apply_style("{" * style * "}" * s * "{/" * style * "}")
    left, right = σ(box.mid.left), σ(box.mid.right)

    # get an empty padding line
    empty = if isnothing(background)
        [Segment(left * " "^(panel_measure.w - 2) * right)]
    else
        [Segment(left * "{$background}" * " "^(panel_measure.w - 2) * "{/$background}" * right)]
    end
    # @debug "rendering" panel_measure Δw

    # check if we need extra lines at the bottom to reach target height
    n_extra = if content_measure.h < panel_measure.h - Δh - 2
        panel_measure.h - content_measure.h - Δh - 2
    else
        0
    end
    # create segments
    initial_segments = Segment[
        top,                                        # top border
        repeat(empty, padding.top)...,              # top padding
    ]

    # content
    content_sgs::Vector{Segment} = if content.measure.w > 0
        map(
            s -> makecontent_line(
                s,
                panel_measure,
                justify,
                background,
                padding,
                left,
                right,
                Δw,
            ),
            content.segments,
        )
    else
        []
    end

    final_segments = Segment[
        repeat(empty, n_extra)...,                  # lines to reach target height
        repeat(empty, padding.bottom)...,           # bottom padding
        bottom * "\e[0m",                           # bottom border
    ]

    segments = vcat(initial_segments, content_sgs, final_segments)
    return Panel(segments, Measure(segments))
end

# ---------------------------------------------------------------------------- #
#                              PANEL LAYOUT MACRO                              #
# ---------------------------------------------------------------------------- #

"""
    function parse_layout_args end

Parse the arguments of a `Expr(:call, :Panel, ...)` to 
add a keyword argument to fix the panel's width. 
A few diferent menthods are defined to handle different combinations
of args/kwargs for the Panel call.
"""
function parse_layout_args end

""" `Panel` had no args/kwargs """
function parse_layout_args(depth)
    w = console_width()
    Δw = 6
    kwargs_arg = Expr(:parameters, Expr(:kw, :width, w - Δw * depth))
    content_args = []
    return kwargs_arg, content_args
end

""" `Panel`'s args did not start with an `Expr` (e.g. a string) """
function parse_layout_args(depth, firstarg, args...)
    w = console_width()
    Δw = 6
    kwargs_arg = Expr(:parameters, Expr(:kw, :width, w - Δw * depth))
    return kwargs_arg, [firstarg, args...]
end

""" `Panels`'s first argument was an `Expr`, nested content! """
function parse_layout_args(depth, firstarg::Expr, args...)
    w = console_width()
    Δw = 6

    if firstarg.head == :parameters
        kwargs_arg = Expr(:parameters, Expr(:kw, :width, w - Δw * depth), firstarg.args...)
        content_args = collect(args)
    else
        kwargs_arg = Expr(:parameters, Expr(:kw, :width, w - Δw * depth))
        # content_args = length(args) > 1 ? collect(args[2:end]) : []
        content_args = [firstarg, args...]
    end

    # @debug "in here" firstarg args kwargs_arg content_args

    return kwargs_arg, content_args
end

"""
    fix_layout_width(panel_call::Expr, depth::Int)::Expr

Go through an `Expr` with a `:call` to a `Panel` and add a keyword
argument expression with the correct `width` (using `parse_layout_args`).
Also go through any other argument to the call to fix inner panels' width.
"""
function fix_layout_width(panel_call::Expr, depth::Int)::Expr
    # @debug "Starting" panel_call.args
    kwargs_arg, content_args = parse_layout_args(depth, panel_call.args[2:end]...)

    # @debug "got ready" content_args kwargs_arg
    for (i, arg) in enumerate(content_args)
        !isa(arg, Expr) && continue

        if arg.head == :call && arg.args[1] == :Panel
            content_args[i] = fix_layout_width(arg, depth + 1)
        end
    end
    return Expr(:call, :Panel, kwargs_arg, content_args...)
end

"""
    macro nested_panels(layout_call)

Macro to automate layout of multiple nested `Panel`. The width of the
panels is automatically adjusted based on the depth of eeach nested level.

Uses `fix_layout_width` recursively to add a keyword argument `width` to each
`Panel`.
"""
macro nested_panels(layout_call)
    if layout_call.head != :call || layout_call.args[1] != :Panel
        error("Layout only works for nested `Panel`")
    end

    layout_call = fix_layout_width(layout_call, 0)
    quote
        $layout_call
    end |> esc
end

# ---------------------------------------------------------------------------- #
#                                    TextBox                                   #
# ---------------------------------------------------------------------------- #

TextBox(args...; kwargs...) = Panel(args...; box = get(kwargs, :box, :NONE), kwargs...)

end
