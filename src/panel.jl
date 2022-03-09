module panel
import Term:
    split_lines,
    get_last_valid_str_idx,
    reshape_text,
    do_by_line,
    join_lines,
    truncate,
    textlen

import ..consoles: console_width
import ..measure: Measure
import ..renderables: AbstractRenderable, RenderablesUnion, Renderable, RenderableText
import ..segment: Segment
using ..box
import ..layout: Padding, vstack
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
        title::Union{Nothing, String}=nothing,
        title_style::Union{String, Nothing}=nothing,
        title_justify::Symbol=:left,
        subtitle::Union{String, Nothing}=nothing,
        subtitle_style::Union{String, Nothing}=nothing,
        subtitle_justify::Symbol=:left,
        width::Union{Nothing, Symbol, Int}=:fit,
        height::Union{Nothing, Int}=nothing,
        style::Union{String, Nothing}=nothing,
        box::Symbol=:ROUNDED,
        justify=:left
    )

`Panel` constructor to fit a panel to a piece of (renderable) content.

`title` can be used to specify a title to be addded to the top row and 
`title_style` and `title_justify` set its appearance and position.
Same for `subtitle` but for the panel's bottom row.
`width` and `height` are used to set the `Panel`'s size. If not passed
they are computed to fit tot the `content`'s size.
"""
function Panel(
    content::RenderablesUnion;
    title::Union{Nothing,String} = nothing,
    title_style::Union{String,Nothing} = nothing,
    title_justify::Symbol = :left,
    subtitle::Union{String,Nothing} = nothing,
    subtitle_style::Union{String,Nothing} = nothing,
    subtitle_justify::Symbol = :left,
    width::Union{Nothing,Symbol,Int} = :fit,
    height::Union{Nothing,Int} = nothing,
    style::Union{String,Nothing} = nothing,
    box::Symbol = :ROUNDED,
    justify = :left,
)
    box = eval(box)  # get box object from symbol

    # style stuff
    title_style = isnothing(title_style) ? style : title_style
    # σ(s) = Segment(s, style)  # applies the main style markup to a string to make a segment
    σ(s) = "[$style]$s[/$style]"  # applies the main style markup to a string to make a segment

    # get size of panel to fit the content
    if content isa AbstractString && width isa Number
        content = do_by_line((ln) -> reshape_text(ln, width - 4), content)
    end

    content_measure = Measure(content)
    panel_measure = Measure(content_measure.w + 2, content_measure.h + 2)

    if width == :fit
        width = panel_measure.w + 2
    else
        width = isnothing(width) ? console_width() - 4 : width
    end
    @assert width > content_measure.w "Width too small for content '$content' with $content_measure"
    panel_measure.w = width
    panel_measure.h = isnothing(height) ? panel_measure.w : height

    # create segments
    segments::Vector{Segment} = []

    # create top/bottom rows with titles
    top = get_title_row(
        :top,
        box,
        title;
        width = width - 2,
        style = style,
        title_style = title_style,
        justify = title_justify,
    )

    bottom = get_title_row(
        :bottom,
        box,
        subtitle;
        width = width - 2,
        style = style,
        title_style = subtitle_style,
        justify = subtitle_justify,
    )

    # add a panel row for each content row
    push!(segments, top)
    left, right = σ(string(box.mid.left)), σ(string(box.mid.right))
    content_lines = split_lines(content)

    for n in 1:(content_measure.h)
        # get padding
        line = content_lines[n]
        padding = Padding(line, width - 2, justify)

        # make line
        segment = Segment(left * padding.left * apply_style(line) * padding.right * right)

        push!(segments, segment)
    end

    # add empty lines to ensure target height is reached
    if !isnothing(height) && content_measure.h < height - 2
        for i in 1:(height - content_measure.h - 2)
            line = " "^(width - 2)
            push!(segments, Segment(left * line * right))
        end
    end
    push!(segments, bottom)

    return Panel(
        segments, Measure(segments), isnothing(title) ? title : title, title_style, style
    )
end

"""
    Panel(renderables; kwargs...)

`Panel` constructor for creating a panel out of multiple renderables at once.
"""
function Panel(renderables...; width::Union{Nothing,Int,Symbol} = nothing, kwargs...)
    rend_width = isnothing(width) || width isa Symbol ? width : width - 1
    renderable = vstack(Renderable.(renderables, width = rend_width)...)

    return Panel(renderable; width = width, kwargs...)
end

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
If no `width` is passed and `fit=:fit` the `TextBox`'s size
matches the size of the input `text`.
Other arguments behave like `Panel`.

See also [`Panel`](@ref).
"""
function TextBox(
    text::Union{Vector,AbstractString};
    width::Union{Nothing,Int} = nothing,
    title::Union{Nothing,String} = nothing,
    title_style::Union{String,Nothing} = "default",
    title_justify::Symbol = :left,
    subtitle::Union{String,Nothing} = nothing,
    subtitle_style::Union{String,Nothing} = "default",
    subtitle_justify::Symbol = :left,
    justify::Symbol = :left,
    fit::Symbol = :fit,
)

    # fit text
    width = isnothing(width) ? console_width() - 4 : width
    if !isnothing(width)
        text = do_by_line((ln) -> reshape_text(ln, width - 4), text)
    elseif fit == :truncate
        text = do_by_line(ln -> truncate(ln, width - 4), text)
    elseif fit == :fit
        width = Measure(text).w + 4
        width = width < 4 ? 4 : width
    end

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
    )

    return TextBox(panel.segments, panel.measure)
end

TextBox(texts...; kwargs...) = TextBox(join_lines(texts); kwargs...)

end
