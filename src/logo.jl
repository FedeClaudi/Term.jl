function make_logo()
    circle = """
        oooo    
    oooooooooo 
    oooooooooooo
    oooooooooooo
    oooooooooo 
        oooo    """



    # create circles
    green = Panel(
        RenderableText(circle, "#389826 bold"),
        style = "dim #389826",
        justify = :center,
        title = "[italic]Made",
        title_style = "bold red",
    )
    red = Panel(
        RenderableText(circle, "#CB3C33 bold"),
        style = "dim #CB3C33",
        justify = :center,
        subtitle = "[italic]with",
        subtitle_style = "bold #b656e3",
        subtitle_justify = :right,
    )
    purple = Panel(
        RenderableText(circle, "#9558B2 bold"),
        style = "dim #9558B2",
        justify = :center,
        subtitle = "[italic]Term",
        subtitle_style = "bold #389826",
    )


    indigo = "#42A5F5"

    as_code(x) = "[orange1 italic]`$x`[/orange1 italic]"

    main = TextBox(
        """

        Term.jl is a [#9558B2]Julia[/#9558B2] package for creating  styled terminal outputs.

        Term provides a simple [italic green4 bold]markup language[/italic green4 bold] toadd [bold bright_blue]color[/bold bright_blue] and [bold underline]styles[/bold underline] to your text.
        
        More complicated text layout can be 
        created using $(as_code("Renderable")) objects such 
        as $(as_code("Panel")) and $(as_code("TextBox")).
        These can also be nested and stacked to 
        create [italic pink3]fancy[/italic pink3] and [underline]informative[/underline] terminal
        ouputs for your Julia code.""",
        title = "Term.jl",
        title_style = indigo * " bold",
        width = 45,
    )


    # create "spacers" and stack renderables
    hspacer = Spacer(green.measure.w / 2 + 1, green.measure.h)
    circles =
        Spacer(green.measure.w * 2 + 2, 1) / (hspacer * green * hspacer) /
        (red * Spacer(2, purple.measure.h) * purple)

    vspacer = Spacer(2, circles.measure.h)
    content = circles * vspacer * vLine(circles.measure.h; style = indigo * " dim") * (Spacer(main.measure.w, 1) / main)

    # add second message
    second_message = TextBox(
        """
        Term.jl can also be used to create [underline]fancy[/underline] $(as_code("logging")) and $(as_code("error")) messages. 
        
        Check the examples and documentation for more information!
        Term.jl is under [bold]active[/bold] development, get in touch for questions or ideas on   how to improve it!""",
        width = content.measure.w,
    )
    hline = hLine(content.measure.w; style=indigo * " dim")
    content = content / second_message

    # add a final message
    msg = """[#75b6e0]Term.jl is based on the [underline]Python[/underline] library [orange1 italic]Rich[/orange1 italic] by [/#75b6e0]Will McGugan. 
                        [dim]https://github.com/Textualize/rich[/dim]"""


    logo =
        Panel(
            content,
            title = "Term.jl",
            title_style = "bold $indigo",
            style = "dim $indigo",
            subtitle = "https://github.com/FedeClaudi/Term.jl",
            subtitle_justify = :right,
            subtitle_style = "dim",
            width = :fit,
        ) / "" / (Spacer(18, 2) * msg)

    return logo
end

