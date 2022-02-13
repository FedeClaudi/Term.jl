module Term

    include("colors.jl")
    include("modes.jl")
    include("utils.jl")

    include("renderable.jl")
    include("markup.jl")
    include("text.jl")
    include("info.jl")

    import .renderable: AbstractRenderable
    import .markup: Tag
    import .text: MarkupText

    export Tag, MarkupText
    export tprint, info

    """ 
        tprint(text::String)

    Stylized printing of a string as MarkupText
    """
    tprint(text::String) = tprint(MarkupText(text))

    """ 
        tprint(text::AbstractRenderable)

    Prints the string field of an AbstractRenderable
    """
    tprint(text::AbstractRenderable) = println(text.string)


    function tag_info(t)
        tprint("""
        [bold green]Tag[/bold green]:
            [yellow]range[/yellow]: [cyan]$(t.start_idx):$(t.end_idx)[/cyan]
            [yellow]text[/yellow]: [cyan]$(t.text)[/cyan]
            [yellow]color[/yellow]: [$(t.colorname)]$(t.colorname) (code: $(t.color))[/$(t.colorname)]
            [yellow]mode[/yellow]: [$(t.modename) white]$(t.modename) (code: $(t.mode))[/$(t.modename) white]
            [yellow]background[/yellow]: [$(t.bg_colorname) white]$(t.bg_colorname) (code: $(t.background))[/$(t.bg_colorname) white]
        """)
    end

end

