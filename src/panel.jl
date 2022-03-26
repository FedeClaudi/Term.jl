module panel
import Term:
    split_lines,
    reshape_text,
    do_by_line,
    join_lines,
    truncate,
    textlen,
    fillin,
    do_by_line

import ..consoles: console_width, console_height
import ..measure: Measure
import ..renderables: AbstractRenderable, RenderablesUnion, Renderable, RenderableText
import ..segment: Segment
using ..box
import ..layout: pad, vstack, Padding
import ..style: apply_style

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
end





"""
    Panel(
            style::String,
            title_style::String,
            title_justify::Symbol,
            subtitle::String,
            subtitle_style::String,
            subtitle_justify::String,
            panel_measure::Measure,
            content_measure::Measure,
            Δw::Int,
            Δh::Int,
            padding::Padding
        )

Construct a `Panel` given all required info.
"""
function render_panel(
                content;
                box::Symbol=:ROUNDED,
                style::String="default",
                title::Union{String,Nothing} = nothing,
                title_style::String = "default",
                title_justify::Symbol = :left,
                subtitle::Union{String,Nothing} = nothing,
                subtitle_style::String = "default",
                subtitle_justify::Symbol = :left,
                justify::Symbol = :left,
                panel_measure::Measure,
                content_measure::Measure,
                Δw::Int,
                Δh::Int,
                padding::Padding
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
    σ(s) = apply_style("[" * style * "]" * s * "[/" * style * "]")
    left, right = σ(box.mid.left), σ(box.mid.right)

    # get an empty padding line
    empty = [Segment(left * " "^(panel_measure.w-2) * right)]

    # add lines with content fn
    function makecontent_line(cline)::Segment
        line = pad(apply_style(cline), panel_measure.w-Δw, justify)
        line = pad(line, padding.left, padding.right)

        # make line
        return Segment(left * line * right)
    end

    # check if we need extra lines at the bottom to reach target height
    if content_measure.h < panel_measure.h - 2 - Δh
        n_extra = panel_measure.h-2 - content_measure.h
    else
        n_extra = 0
    end

    # create segments
    initial_segments::Vector{Segment} = [
        top,                                        # top border
        repeat(empty, padding.top)...,              # top padding
    ]

    # content
    content_sgs::Vector{Segment} = content.measure.w > 0 ?  map(s -> makecontent_line(s.text), content.segments) : []  
        
    final_segments::Vector{Segment} = [
        repeat(empty, n_extra)...,                  # lines to reach target height
        repeat(empty, padding.bottom)...,           # bottom padding
        bottom,                                     # bottom border
    ]

    segments = vcat(initial_segments, content_sgs, final_segments)

    return Panel(
        segments, panel_measure
    )
end

"""
    Panel(; 
        fit::Symbol=:nofit,
        width::Int = 88,
        height::Union{Nothing,Int} = nothing, 
        kwargs...
    )

Construct a `Panel` with no content
"""
function Panel(; 
            fit::Bool=false,
            width::Int = 88,
            height::Int = 2, 
            padding::Union{Vector, Padding, NTuple} = Padding(0, 0, 0, 0),
            kwargs...
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
        panel_measure=panel_measure,
        content_measure=content_measure,
        Δw=padding.left + padding.right + 2,
        Δh=padding.top + padding.bottom,
        padding=padding,
        kwargs...
    )
end


"""
    Panel(
        content::AbstractRenderable;
        width::Int = 88,
        height::Union{Nothing,Int} = nothing,
        fit::Bool=false,
        padding::Union{Padding, NTuple} = Padding(2, 2, 0, 0),
        kwargs...
    )

Construct a `Panel` around of a `AbstractRenderable`
"""
function Panel(
        content::Union{AbstractString, AbstractRenderable};
        width::Int = 88,
        height::Union{Nothing,Int} = nothing,
        fit::Bool=false,
        padding::Union{Padding, NTuple} = Padding(2, 2, 0, 0),
        kwargs...
    )

    # get measure
    WIDTH = console_width(stdout)
    padding = padding isa Padding ? padding : Padding(padding...)
    Δw = padding.left + padding.right + 2
    Δh = padding.top + padding.bottom

    # define convenience function
    function resize_content(content, _width)
        if content isa RenderableText
            content = RenderableText(content; width=_width)
        elseif content isa AbstractString
            content = RenderableText(content; width=_width+1)
        end
        return content, content.measure
    end

    # get measure of panel's box and optionally resize text.
    content_measure = Measure(content)
    if fit
        # if content width too large, resize content if its text renderable
        if content_measure.w > WIDTH - Δw
            content, content_measure = resize_content(content, WIDTH - Δw )
            panel_measure = Measure(WIDTH, content_measure.h+Δh+2)
        else
            panel_measure = Measure(content_measure.w+Δw, content_measure.h+Δh+2)
        end
    end

    if !fit
        # check that the content fits within the given width
        if content isa RenderableText || content isa AbstractString
            width = min(width, WIDTH)
            if content_measure.w > width-Δw
                content, content_measure = resize_content(content, width-Δw)
            end
        else
            # if width too small for content, try to enlarge
            width = width < content_measure.w+Δw ?  min(content_measure.w+Δw, WIDTH-Δw) : width
        end

        # get target height
        _h = content_measure.h + Δh + 2
        height = isnothing(height) ? _h  : max(height, _h)
        panel_measure = Measure(width, height)
    end

    if content isa String
        content = RenderableText(content)
    end

    return render_panel(
        content;
        panel_measure=panel_measure,
        content_measure=content_measure,
        Δw=Δw,
        Δh=Δh,
        padding=padding,
        kwargs...
    )
end




"""
    Panel(renderables; kwargs...)

`Panel` constructor for creating a panel out of multiple renderables at once.
"""
Panel(renderables::Vector; kwargs...) = Panel(vstack(renderables...); kwargs...)
Panel(renderables...; kwargs...) = Panel(vstack(renderables...); kwargs...)

# ---------------------------------------------------------------------------- #
#                                    TextBox                                   #
# ---------------------------------------------------------------------------- #

"""
    TextBox

Creates a `Panel` and fits input text to it.
The pannel is hidden so that the result is just a text box.
"""
mutable struct TextBox <: AbstractPanel
    segments::Vector
    measure::Measure
end

"""
    TextBox(
        text::Union{Vector, AbstractString};
        width::Union{Nothing, Int}=nothing,
        title::Union{Nothing, String}=nothing,
        title_style::Union{String, Nothing}="default",
        title_justify::Symbol=:left,
        subtitle::Union{String, Nothing}=nothing,
        subtitle_style::Union{String, Nothing}="default",
        subtitle_justify::Symbol=:left,
        justify::Symbol=:left,
        fit::Symbol=:fit,
        )

Creates an hidden `Panel` with `text` in it.

If a `width` is passed, the input `text` is reshaped to have
that size, unless `fit=:truncate` in which case it's cut to size.
If no `width` is passed and `fit=true` the `TextBox`'s size
matches the size of the input `text`.
Other arguments behave like `Panel`.

See also [`Panel`](@ref).
"""
function TextBox(
    text::Union{AbstractString};
    width::Int = 88,
    title::Union{Nothing,String} = nothing,
    title_style::Union{String,Nothing} = "default",
    title_justify::Symbol = :left,
    subtitle::Union{String,Nothing} = nothing,
    subtitle_style::Union{String,Nothing} = "default",
    subtitle_justify::Symbol = :left,
    justify::Symbol = :left,
    fit::Symbol = :nofit,
)
    # fit text or get width
    if fit==:fit
        # the box's size depends on the text's size
        width = Measure(text).w + 4

        # too large, fit to console
        if width > console_width(stdout)
            width=console_width(stdout)
            fit = true
        end
    else
        width = width > console_width(stdout) ? console_width(stdout) - 4 : width
    end

    # truncate or reshape text
    if fit == :truncate
        # truncate the text to fit the given width
        text = do_by_line(ln -> truncate(ln, width - 7), text)
    else
        text = do_by_line((ln) -> reshape_text(ln, width - 6), text)
    end
    
    # create panel with text inside
    panel = Panel(
        text;
        style = "hidden",
        title = title,
        title_style = title_style,
        title_justify = title_justify,
        subtitle = subtitle,
        subtitle_style = subtitle_style,
        subtitle_justify = subtitle_justify,
        justify = justify,
        width = width,
        fit=false
    )

    return TextBox(panel.segments, Measure(panel.measure.w, panel.measure.h))
end

TextBox(texts...; kwargs...) = TextBox(join_lines(texts...); kwargs...)

end
 