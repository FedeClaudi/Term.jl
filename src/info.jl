import .markup: Tag

function info(t::Tag)
    def = "{$(t.definition)}$(t.text){/$(t.definition)}"
    tprint("""
    [bold green]Tag[/bold green]:
        [yellow]text[/yellow]: "$def"
       $("_"^(length(def)+8))
        [yellow]range[/yellow]: [cyan]$(t.start_idx):$(t.end_idx)[/cyan]
        [yellow]text[/yellow]: [cyan]$(t.text)[/cyan]
        [yellow]color[/yellow]: [$(t.colorname)]$(t.colorname) (code: $(t.color))[/$(t.colorname)]
        [yellow]mode[/yellow]: [$(t.modename) white]$(t.modename) (code: $(t.mode))[/$(t.modename) white]
        [yellow]background[/yellow]: [$(t.bg_colorname) white]$(t.bg_colorname) (code: $(t.background))[/$(t.bg_colorname) white]
    """)
end
