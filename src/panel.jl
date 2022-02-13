module panel
    include("utils.jl")

    import ..renderable: AbstractPanel
    import ..box: get_row, ALL_BOXES
    import ..text: apply_style, apply_style_to_lines
    import ..measure: Measure

    """
    Renderable with a panel around another piece of content
    """
    mutable struct Panel <: AbstractPanel
        content::Union{String, AbstractRenderable}
        style::Union{String, Nothing}
        string::String
    end


    """
    Fit a panel to a piece of (renderable) content.
    """
    function Panel(
                content::Union{String, AbstractRenderable};
                width::Union{Nothing, Int}=nothing,
                style::Union{String, Nothing}=nothing,
                box::Symbol=:ROUNDED,
                justify=:left
        )
        box = ALL_BOXES[box]

        # get style
        σ(s) = apply_style(s, style)

        # get size of content and measure
        if typeof(content) <: AbstractString
            content = apply_style_to_lines(content)
        end
        content_measure = Measure(content)
        panel_measure = Measure(content_measure.width+2, content_measure.height+2)
        width = isnothing(width) ? panel_measure.width : width
        @assert width >= panel_measure.width "With too small, not yet supported"

        # create rows of strings
        lines = []
        push!(lines, σ(get_row(box, [width], :top)))  # make top row

        # add a panel row for each content row
        left, right = σ(string(box.mid.left)), σ(string(box.mid.right))
        content_lines = split_lines(content)
        for n in 1:content_measure.height
            # get padding
            line = content_lines[n] 
            padding = Padding(line, width, justify)

            # make line
            push!(lines, left * apply_style(padding.left * line * padding.right) * right)
        end
        push!(lines, σ(get_row(box, [width], :bottom)))  # make bottom row


        return Panel(
            content,
            style,
            merge_lines(lines)
        )
    end
end