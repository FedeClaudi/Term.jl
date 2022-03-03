module panel
    import Term: split_lines, get_last_valid_str_idx, rehsape_text, do_by_line, join_lines, truncate

    import ..consoles: console
    import ..measure: Measure
    import ..renderables: AbstractRenderable, RenderablesUnion, Renderable, RenderableText
    import ..segment: Segment
    using ..box
    import ..layout: Padding, vstack

    export Panel, TextBox


    abstract type AbstractPanel <: AbstractRenderable end

    # ---------------------------------------------------------------------------- #
    #                                     PANEL                                    #
    # ---------------------------------------------------------------------------- #
    """
    Renderable with a panel around another piece of content (text or AbstractRenderable).
    """
    mutable struct Panel <: AbstractPanel
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
                height::Union{Nothing, Int}=nothing,
                style::Union{String, Nothing}=nothing,
                box::Symbol=:ROUNDED,
                justify=:left
        )
        box = eval(box)  # get box object from symbol

        # style stuff
        title_style = isnothing(title_style) ? style : title_style
        # σ(s) = Segment(s, style)  # applies the main style markup to a string to make a segment
        σ(s) = "[$style]$s[/$style]"  # applies the main style markup to a string to make a segment

        # get size of panel to fit the content
        if content isa AbstractString && !isnothing(width)
            # content = rehsape_text(content, width-2)
            content = do_by_line((ln)->rehsape_text(ln, width-4), content)
        end
        content_measure = Measure(content)
        panel_measure = Measure(content_measure.w+2, content_measure.h+2)

        width = isnothing(width) ? console.width-4 : width
        @assert width > content_measure.w "Width too small for content '$content' with $content_measure"
        panel_measure.w = width

        # @info "Creating panel" content_measure panel_measure typeof(content)

        # create segments
        segments::Vector{Segment} = []

        # create top/bottom rows with titles
        top = get_title_row(:top,
                    box, 
                    title; 
                    width=width-2,
                    style=style,
                    title_style=title_style,
                    justify=title_justify)

        bottom = get_title_row(:bottom,
                    box,
                    subtitle; 
                    width=width-2,
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
            padding = Padding(line, width-2, justify)

            # make line
            segment = Segment(left * padding.left * line * padding.right * right)
            # @info "pl" left.plain padding.left padding.right right.plain
            # @info "panel line" line padding segment segment.plain Measure(segment.plain)

            push!(segments, segment)

            # @assert segment.measure.w <= panel_measure.w "\e[31mTarget measure: $panel_measure, segment has $(segment.measure), pading: $padding, line length: $(length(line))"
        end

        # add empty lines to ensure target height is reached
        if !isnothing(height) && content_measure.h < height
            for i in 1:(height - content_measure.h)
                line = " "^(width)
                push!(segments, Segment(left * line * right))
            end
        end

        push!(segments, bottom)

        # @assert max([Measure(s).w for s in segments]...) <= panel_measure.w "\e[31mSegments too large"

        return Panel(
            segments, 
            panel_measure,
            isnothing(title) ? title : title,
            title_style,
            style,
        )

    end

    """
        Panel(renderables; kwargs...)

    `Panel` constructor for creating a panel out of multiple renderables at once.
    """
    function Panel(renderables...; width::Union{Nothing, Int}=nothing, kwargs...)
        rend_width = isnothing(width) ? width : width-1
        renderable = vstack(Renderable.(renderables, width=rend_width)...)

        return Panel(renderable; width=width, kwargs...)
    end




    # ---------------------------------------------------------------------------- #
    #                                    TextBox                                   #
    # ---------------------------------------------------------------------------- #
    
    """
        TextBox

    Creates a panel and fits input text to it.
    The pannel is hidden so that the result is just a text box.
    """
    mutable struct TextBox <: AbstractPanel
        segments::Vector
        measure::Measure
    end


    function TextBox(
        text::Union{Vector, AbstractString};
        width::Union{Nothing, Int}=88,
        title::Union{Nothing, String}=nothing,
        title_style::Union{String, Nothing}="default",
        title_justify::Symbol=:left,
        subtitle::Union{String, Nothing}=nothing,
        subtitle_style::Union{String, Nothing}="default",
        subtitle_justify::Symbol=:left,
        justify::Symbol=:left,
        fit::Symbol=:fit,
        )

        # fit text
        width = isnothing(width) ? console.width-4 : width
        if fit == :truncate
            text = do_by_line(ln->truncate(ln, width-4), text)
        elseif fit != :fit
            text = do_by_line((ln)->rehsape_text(ln, width-4), text)
        end
        # @info "\e[31mReshaped text" text Measure(text) width

        panel = Panel(
            text,
            style="hidden",
            title=title,
            title_style=title_style,
            title_justify=title_justify,
            subtitle=subtitle,
            subtitle_style=subtitle_style,
            subtitle_justify=subtitle_justify,
            justify=justify,
            width=width
        )
        

        return TextBox(panel.segments, panel.measure)
    end

    TextBox(texts...;kwargs...) = TextBox(join_lines(texts); kwargs...)

end