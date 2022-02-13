module Term

    include("colors.jl")
    include("modes.jl")
    include("utils.jl")
    include("tag.jl")
    include("style.jl")

    import .Tags: Tag
    import .Styles: inject_style

    export inject_style, Tag
    export tprint

    """ Stylized printing"""
    tprint(text::String) = (println ∘ inject_style)(text)


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

