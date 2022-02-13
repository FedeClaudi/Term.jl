module panel
    include("utils.jl")

    import ..renderable: AbstractPanel, AbstractRenderable
    import ..box: get_row, ALL_BOXES
    import ..text: apply_style, apply_style_to_lines, plain
    import ..measure: Measure, count_codeunits
    import ..layout: Padding
    import ..inspect: info
    import ..markup: ANSI_TAG_CLOSE

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
                title::Union{Nothing, String}=nothing,
                title_style::Union{String, Nothing}=nothing,
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

        # create top and add title
        top = get_row(box, [width], :top)

        if !isnothing(title)
            title=apply_style(title)
            l = length(plain(title))
            @assert l < width - 4 "Title too long for panel of width $width"
            
            # compose title line 
            cut_start = get_last_valid(top, 4)
            pre = top[1:cut_start] * " " * apply_style(title, title_style) * " "
            
            post = box.top.mid^(length(top)-length(plain(pre))-1) * box.top.right
            top = pre * σ(post)
        end

        push!(lines, σ(top))

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