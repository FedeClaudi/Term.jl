module panel
    import Term: split_lines, Measure, get_last_valid_str_idx

    import ..measure: Measure
    import ..renderables: AbstractRenderable, RenderablesUnion, Renderable, RenderableText
    import ..segment: Segment
    using ..box
    import ..style: apply_style
    import ..layout: Padding, vstack

    export Panel

    """
    Renderable with a panel around another piece of content (text or AbstractRenderable)
    """
    mutable struct Panel <: AbstractRenderable
        segments::Vector
        measure::Measure
        title::Union{Nothing, String}
        title_style::Union{String, Nothing}
        style::Union{String, Nothing}
    end



    """
        Panel(
            content::Union{String, AbstractRenderable};
            title::Union{Nothing, String}=nothing,
            title_style::Union{String, Nothing}=nothing,
            width::Union{Nothing, Int}=nothing,
            style::Union{String, Nothing}=nothing,
            box::Symbol=:ROUNDED,
            justify=:left
        )

    `Panel` constructor to fit a panel to a piece of (renderable) content.
    """
    function Panel(
                content::RenderablesUnion;
                title::Union{Nothing, String}=nothing,
                title_style::Union{String, Nothing}=nothing,
                title_justify::Symbol=:left,
                subtitle::Union{String, Nothing}=nothing,
                subtitle_style::Union{String, Nothing}=nothing,
                subtitle_justify::Symbol=:left,
                width::Union{Nothing, Int}=nothing,
                style::Union{String, Nothing}=nothing,
                box::Symbol=:ROUNDED,
                justify=:left
        )
        box = eval(box)  # get box object from symbol

        # pre styles
        title_style = isnothing(title_style) ? style : title_style
        σ(s) = Segment(s, style)  # applies the main style markup to a string to make a segment

        # get size of panel to fit the content
        content_measure = Measure(content)
        panel_measure = Measure(content_measure.w+2, content_measure.h+2)
        width = isnothing(width) ? panel_measure.w : width
        panel_measure.w = width
        @assert width >= panel_measure.w "With too small, not yet supported"

        # create segments
        segments::Vector{Segment} = []

        # create top/bottom rows with titles
        top = get_title_row(:top,
                    box, 
                    title; 
                    width=width,
                    style=style,
                    title_style=title_style,
                    justify=title_justify)

        bottom = get_title_row(:bottom,
                    box,
                    subtitle; 
                    width=width,
                    style=style,
                    title_style=subtitle_style,
                    justify=subtitle_justify)

        # add a panel row for each content row
        push!(segments, top)
        left, right = σ(string(box.mid.left)), σ(string(box.mid.right))
        content_lines = split_lines(content)
        
        for n in 1:content_measure.h
            # get padding
            line = content_lines[n] 
            padding = Padding(line, width, justify)

            # make line
            push!(segments, Segment(left * padding.left * line * padding.right * right))
        end
        push!(segments, bottom)

        return Panel(
            segments, 
            Measure(segments),
            isnothing(title) ? title : title,
            title_style,
            style,
        )

    end

    """
        Panel(renderables; kwargs...)

    `Panel` constructor for creating a panel out of multiple renderables at once.
    """
    function Panel(renderables...; kwargs...)
        renderable = vstack(Renderable.(renderables)...)

        return Panel(renderable; kwargs...)
    end


end