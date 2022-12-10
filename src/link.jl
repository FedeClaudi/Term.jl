module Links
    import ..Measures: Measure
    import ..Segments: Segment
    import ..Style: apply_style
    import ..Renderables: RenderableText, AbstractRenderable
    import ..Renderables
    import ..Layout: pad
    import Term: get_relative_path, textlen, TERM_THEME, cleantext

    export Link


    struct Link <: AbstractRenderable
        segments::Vector{Segment}
        measure::Measure
        display_text::String
        link::String
        style::String
    end

    function Link(file_path::AbstractString, line_number::Union{Nothing, Integer}=nothing; style=TERM_THEME[].link)
        link = isnothing(line_number) ? file_path : "$file_path#$line_number"
        short_path = get_relative_path(file_path)
        display_text = isnothing(line_number) ? short_path : "$short_path $(line_number)"
        clickable_link = "\x1b]8;;$link\x1b\\$display_text\x1b]8;;\x1b\\"

        m = Measure(1, textlen(display_text))
        return Link(
            [Segment(apply_style("{$(style)}" * clickable_link * "{/$(style)}"), m)],
            m, display_text, link, style
        )
    end

    function Renderables.RenderableText(link::Link, args...;     
        style::Union{Nothing,String} = link.style,
        width::Int = link.measure.w,
        background::Union{Nothing,String} = nothing,
        justify::Symbol = :left,)
        


        display_text = pad(cleantext(link.display_text), width-link.measure.w, justify; bg=background)
        clickable_link = "\x1b]8;;$(link.link)\x1b\\$display_text\x1b]8;;\x1b\\"

        return RenderableText(
            [Segment(apply_style("{$(style)}" * clickable_link * "{/$(style)}"), link.measure)],
            link.measure, style
        )
    end
end



# path = "/Users/federicoclaudi/Documents/Github/Term.jl/src/_utils.jl"
# link = Links.get_clickable_link(path)
# Renderable(link).measure

# # rvstack(link, "aa")