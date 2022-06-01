module Panels

import Term:
    split_lines, reshape_text, do_by_line, join_lines, truncate, textlen, fillin, do_by_line, ltrim_str

import ..Renderables: AbstractRenderable, RenderablesUnion, Renderable, RenderableText
import ..Console: console_width, console_height
import ..Layout: pad, vstack, Padding, lvstack
import ..Style: apply_style
import ..Segments: Segment
import ..Measures: Measure
import ..Measures: height as get_height
import ..Measures: width as get_width
using ..Boxes

export Panel, TextBox

abstract type AbstractPanel <: AbstractRenderable end

# ---------------------------------------------------------------------------- #
#                                     PANEL                                    #
# ---------------------------------------------------------------------------- #
"""
    Panel

`Renderable` with a panel surrounding some content:
        ╭──────────╮
        │ my panel │
        ╰──────────╯
"""
mutable struct Panel <: AbstractPanel
    segments::Vector
    measure::Measure

    function Panel(x1, x2; kwargs...)
        # this is necessary to handle the special case in which 2 objs are passed
        # but they are not segments/measure
        if x1 isa Vector
            return new(x1, x2)
        else
            return Panel(vstack(x1, x2); kwargs...)
        end
    end
end




"""
    Panel(; 
        fit::Symbol=:nofit,
        width::Int = 88,
        height::Union{Nothing,Int} = nothing, 
        kwargs...
    )

Construct a `Panel` with no content.

# Examples
julia> Panel(; width=10, height=5)
╭────────╮
│        │
│        │
│        │
╰────────╯
"""
function Panel(;
    fit::Bool = false,
    width::Int = 88,
    height::Int = 2,
    padding::Union{Vector,Padding,NTuple} = Padding(0, 0, 0, 0),
    kwargs...,
)
    # get panel measure
    if fit
        # hardcoded size of empty 'fitted' panel
        panel_measure = Measure(3, 2)
    else
        panel_measure = Measure(width, height)
    end

    # get empty content measure
    content = ""
    content_measure = Measure(0, 0)

    # get padding
    padding = padding isa Padding ? padding : Padding(padding...)

    # make panel
    return Panel(
        content;
        panel_measure = panel_measure,
        content_measure = content_measure,
        Δw = padding.left + padding.right + 2,
        Δh = padding.top + padding.bottom,
        height=height, width=width,
        padding = padding,
        kwargs...,
    )
end

"""
    Panel(
        content::Union{AbstractString,AbstractRenderable},
        ::Val{true},
        padding::Padding;
        kwargs...
        )

Construct a `Panel` fitting with content.
"""
function Panel(
    content::Union{AbstractString,AbstractRenderable},
    ::Val{true},
    padding::Padding;
    kwargs...
    )
    content = content isa AbstractRenderable ? content : RenderableText(content)

    content_measure = content.measure
    panel_measure = Measure(
        content_measure.w + padding.left + padding.right + 2,
        content_measure.h + padding.top + padding.bottom
    )
    Δw = padding.left + padding.right + 2
    Δh = padding.top + padding.bottom

    return render(content;
        panel_measure=panel_measure,
        content_measure=content_measure,
        Δw=Δw, 
        Δh=Δh, 
        padding=padding,
        kwargs...
    )

end

function Panel(
    content::Union{AbstractString,AbstractRenderable},
    ::Val{false},
    padding::Padding;
    width::Int = 88,
    height::Union{Nothing,Int} = nothing,
    kwargs...
    )
    
    Δw = padding.left + padding.right + 2
    Δh = padding.top + padding.bottom + 1

    height = isnothing(height) ? get_height(content) + Δh  : height
    panel_measure = Measure(width, height)

    # if the content is too large, resize it to fit the panel's width.
    if get_width(content) > width - Δw + 1
        if content isa AbstractString
            # @info "reshaping" content
            content = reshape_text(content, width - Δw)
        else
            segments = lvstack(map(s -> 
            ltrim_str(s.text, width - Δw), 
            content.segments)).segments
            # @info "RESHAPEEEE"
            
            content = Renderable(segments, Measure(segments))
        end
    end
    content = content isa AbstractRenderable ? content : RenderableText(content)

    # if the content is too tall, exclude some lines
    if content.measure.h > height - Δh - 1
        # @info "truncating" content.measure  height - Δh - 1
        segments = [
            content.segments[1:height-Δh-3]...
            Segment("... content omitted ...", "dim")
        ]

        content = Renderable(
            segments, Measure(segments)
        )
    end
    return render(content;
        panel_measure=panel_measure, 
        content_measure=content.measure,
        Δw=Δw, 
        Δh=Δh, 
        padding=padding,
        kwargs...
    )
end


"""
    Panel(
        content::Union{AbstractString,AbstractRenderable};
        width::Int = 88,
        height::Union{Nothing,Int} = nothing,
        fit::Bool=false,
        padding::Union{Padding, NTuple} = Padding(2, 2, 0, 0),
        kwargs...
    )

Construct a `Panel` around of a `AbstractRenderable`
"""
function Panel(
    content::Union{AbstractString,AbstractRenderable};
    fit::Bool = false,
    padding::Union{Padding,NTuple} = Padding(2, 2, 0, 0),
    kwargs...,
) 
    padding = padding isa Padding ? padding : Padding(padding...)
    isfit = fit ? Val(true) : Val(false)
    return Panel(content, isfit, padding; kwargs...)
end



"""
    Panel(renderables; kwargs...)

`Panel` constructor for creating a panel out of multiple renderables at once.
"""
function Panel(renderables::Vector{RenderablesUnion}; kwargs...)
    return Panel(vstack(renderables...); kwargs...)
end

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
    kwargs...
)::Panel

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
    σ(s) = apply_style("{" * style * "}" * s * "{/" * style * "}")
    left, right = σ(box.mid.left), σ(box.mid.right)

    # get an empty padding line
    empty = [Segment(left * " "^(panel_measure.w - 2) * right)]

    # add lines with content fn
    function makecontent_line(cline)::Segment
        line = pad(apply_style(cline), panel_measure.w - Δw, justify)
        line = pad(line, padding.left, padding.right)

        # make line
        return Segment(left * line * right)
    end

    # check if we need extra lines at the bottom to reach target height
    if content_measure.h < panel_measure.h - Δh - 2
        n_extra = panel_measure.h - content_measure.h - Δh - 2
    else
        n_extra = 0
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
        bottom * "\e[0m",                                     # bottom border
    ]

    segments = vcat(initial_segments, content_sgs, final_segments)

    return Panel(segments, panel_measure)
end

# ---------------------------------------------------------------------------- #
#                                    TextBox                                   #
# ---------------------------------------------------------------------------- #

function TextBox(args...; kwargs...)
    box = get(kwargs, :box, :NONE)
    return Panel(args...; box=box, kwargs...)
end

end
