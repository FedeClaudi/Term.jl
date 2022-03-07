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

        Term.jl is a [#9558B2]Julia[/#9558B2] package for creating styled terminal outputs.

        It can be used to [blue]inject[/blue] [bright_green]some[/bright_green] [indian_red]color[/indian_red] [italic]&[/italic] [bold underline italic]style[/bold underline italic] to your text.
        It provides a collection of $(as_code("Renderable")) objects such as $(as_code("Panels")) and $(as_code("TextBoxes")) to create structured content.
        $(as_code("Renderables")) can be [italic]stacked[/italic] to compose them into a larger piece of conent, as showcased here, using operators such as: [bold red underline]*[/bold red underline] & [bold red underline]/[/bold red underline].

        Also, Term.jl provides functionality to create [underline]structured[/underline] $(as_code("logging")) and $(as_code("error")) messages. Check the examples and documentation for more information

        Term.jl is under [bold]active[/bold] development! Get in touch on github or twitter ([italic blue]@Federico_claudi[/italic blue]) with questions or ideas on how to improve it!
        """,
        title = "Term.jl",
        title_style = indigo,
        width = 75,
    )

    # create "spacers" and stack renderables
    hspacer = Spacer(green.measure.w / 2 + 1, green.measure.h)
    circles =
        Spacer(green.measure.w * 2 + 2, 1) / (hspacer * green * hspacer) /
        (red * Spacer(2, purple.measure.h) * purple)

    vspacer = Spacer(2, circles.measure.h)
    content = circles * vspacer * vLine(main.measure.h; style = indigo * " dim") * main


    # add a final message
    msg = """[#75b6e0]Term.jl is based on the [underline]Python[/underline] library [orange1 italic]Rich[/orange1 italic] by [/#75b6e0]Will McGugan. 
                        [dim]https://github.com/Textualize/rich[/dim]
    """


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
        ) / "" / (Spacer(40, 2) * msg)

    return logo
end