module panel
import Term:
    split_lines,
    reshape_text,
    do_by_line,
    join_lines,
    truncate,
    textlen,
    fillin

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
    title::Union{Nothing,String}
    title_style::Union{String,Nothing}
    style::Union{String,Nothing}
end


"""
    Panel(
        content::RenderablesUnion;
        title::Union{Nothing,String} = nothing,
        title_style::Union{String,Nothing} = nothing,
        title_justify::Symbol = :left,
        subtitle::Union{String,Nothing} = nothing,
        subtitle_style::Union{String,Nothing} = nothing,
        subtitle_justify::Symbol = :left,
        style::Union{String,Nothing} = "default",
        box::Symbol = :ROUNDED,
        width::Int = 88,
        height::Union{Nothing,Int} = nothing,
        fit::Symbol=:nofit,
        justify = :left,
    )

`Panel` constructor to fit a panel to a piece of (renderable) content.

`title` can be used to specify a title to be addded to the top row and 
`title_style` and `title_justify` set its appearance and position.
Same for `subtitle` but for the panel's bottom row.
`box` accepts one of the named `Term.box.Box` object and sets
which box should be used.

`width` and `height` are used to set the `Panel`'s size. 
If `fit=true` is passed the width and height arguments are 
ignored and the panel's box is fitted to the content's size
`justify` (:left, :center, :right) defines how the content should
be justified withing the panel. 
`padding` specifies the ammount of padding between the box and the content.
"""
function Panel(
    content::Union{Nothing, RenderablesUnion};
    title::Union{Nothing,String} = nothing,
    title_style::Union{String,Nothing} = nothing,
    title_justify::Symbol = :left,
    subtitle::Union{String,Nothing} = nothing,
    subtitle_style::Union{String,Nothing} = nothing,
    subtitle_justify::Symbol = :left,
    style::Union{String,Nothing} = "default",
    box::Symbol = :ROUNDED,
    width::Int = 88,
    height::Union{Nothing,Int} = nothing,
    fit::Bool=false,
    justify::Symbol = :left,
    padding::Union{Vector, Padding, NTuple} = Padding(2, 2, 0, 0)

)
    box = eval(box)  # get box object from symbol

    # if content is text, ensure all lines have same width
    content = content isa AbstractString ? fillin(content) : content

    # get measure
    WIDTH = console_width(stdout)
    padding = padding isa Padding ? padding : Padding(padding...)
    Δw = padding.left + padding.right + 2
    Δh = padding.top + padding.bottom

    # define convenience function
    function resize_text(content, _width)
        if content isa AbstractString || content isa RenderableText
            content = RenderableText(content; width=_width)
            content_measure = content.measure
            return content, content.measure
        else
            return content, content_measure
        end
    end

    # get measure of panel's box and optionally resize text.
    if isnothing(content)
        if fit
            panel_measure = Measure(3, 2)
        else
            height = isnothing(height) ? 2 : height
            panel_measure = Measure(width, height)
        end
        # panel_measure = Measure(2, 2)
        content = ""
        content_measure = Measure(0, 0)
    else
        content_measure = Measure(content)
        if fit
            # if content width too large, resize content if its text
            if content_measure.w > WIDTH - Δw
                width = WIDTH-Δw
                content, content_measure = resize_text(content, width-Δw+2)
                panel_measure = Measure(width+2, content_measure.h+Δh+2)
            else
                panel_measure = Measure(content_measure.w+Δw, content_measure.h+Δh+2)
            end
        end

        if !fit
            # check that the content fits within the given width
            if content isa AbstractString || content isa RenderableText
                width = min(width, WIDTH)
                if content_measure.w > width-Δw
                    content, content_measure = resize_text(content, width-Δw)
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
    end

    
    # style stuff
    title_style = isnothing(title_style) ? style : title_style
    σ(s) = "[$style]$s[/$style]"  # applies the main style markup to a string to make a segment

    # create segments
    segments::Vector{Segment} = []

    # create top/bottom rows with titles
    top = get_title_row(
        :top,
        box,
        title;
        width = panel_measure.w-2,
        style = style,
        title_style = title_style,
        justify = title_justify,
    )

    bottom = get_title_row(
        :bottom,
        box,
        subtitle;
        width = panel_measure.w-2,
        style = style,
        title_style = subtitle_style,
        justify = subtitle_justify,
    )

    # add a panel row for each content row
    push!(segments, top)

    # add padding lines at top
    left, right = σ(string(box.mid.left)), σ(string(box.mid.right))

    addempty() = push!(segments, Segment(left * " "^(panel_measure.w-2) * right)) 
    for i in 1:padding.top
        addempty()
    end

    content_lines = split_lines(content)

    for n in 1:(content_measure.h)
        # apply style and pad
        line = pad(apply_style(content_lines[n]), panel_measure.w-Δw, justify)
        line = pad(line, padding.left, padding.right)

        # make line
        segment = Segment(left * line * right)

        push!(segments, segment)
    end

    # add empty lines to ensure target height is reached
    if content_measure.h < panel_measure.h - 2 - Δh
        for i in 1:(panel_measure.h-2 - content_measure.h)
            addempty()
        end
    end

    # add padding at the bottom
    for i in 1:padding.bottom
        addempty()
    end

    push!(segments, bottom)

    return Panel(
        segments, panel_measure, title, title_style, style
    )
end

"""
    Panel(renderables; kwargs...)

`Panel` constructor for creating a panel out of multiple renderables at once.
"""
function Panel(content, renderables...; kwargs...)
    content = vstack(content, Renderable.(renderables)...)
    return Panel(content; kwargs...)
end

Panel(content::AbstractVector; kwargs...) = Panel(content...; kwargs...)
Panel(; kwargs...) = Panel(nothing; kwargs...)

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

TextBox(texts...; kwargs...) = TextBox(join_lines(texts); kwargs...)

end
