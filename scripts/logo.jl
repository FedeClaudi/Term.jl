using Term
using Term.Layout

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
        RenderableText(circle; style = "#389826 bold");
        fit = true,
        style = "dim #389826",
        justify = :center,
        padding = (2, 2, 0, 0),
        title = "{italic default}Made",
        title_style = "bold red",
    )
    red = Panel(
        RenderableText(circle; style = "#CB3C33 bold");
        fit = true,
        style = "dim #CB3C33",
        justify = :center,
        padding = (2, 2, 0, 0),
        subtitle = "{italic default}with",
        subtitle_style = "bold #b656e3",
        subtitle_justify = :right,
    )
    purple = Panel(
        RenderableText(circle; style = "#9558B2 bold");
        fit = true,
        style = "dim #9558B2",
        justify = :center,
        padding = (2, 2, 0, 0),
        subtitle = "{italic default}Term",
        subtitle_style = "bold #389826",
    )

    indigo = "#42A5F5"

    as_code(x) = "{orange1 italic}`$x`{/orange1 italic}"

    # create "spacers" and stack renderables
    hspacer = Spacer(green.measure.h, green.measure.w / 2 + 1)
    line = Spacer(1, green.measure.w * 2 + 6)
    circles =
        line / (hspacer * green * hspacer) / (red * Spacer(purple.measure.h, 2) * purple)

    main = TextBox(
        """Term.jl is a {#9558B2}Julia{/#9558B2} package for creating styled terminal outputs.

        Term provides a simple {italic green4 bold}markup language{/italic green4 bold} to add {bold bright_blue}color{/bold bright_blue} and {bold underline}styles{/bold underline} to your text.
        More complicated text layout can be created using $(as_code("Renderable")) objects such 
        as $(as_code("Panel")) and $(as_code("TextBox")).
        These can also be nested and stacked to create {italic pink3}fancy{/italic pink3} and {underline}informative{/underline} terminal outputs for your Julia code""";
        width = 35,
        height = circles.measure.h,
        fit = false,
    )
    content = circles * vLine(main.measure.h; style = indigo * " dim") * main

    # add second message
    second_message = RenderableText(
        """
        Term.jl can also be used to create {underline}fancy{/underline} $(as_code("logging")) and $(as_code("error")) messages. 

        Check the examples and documentation for more information!
        Term.jl is under {bold}active{/bold} development, get in touch for questions or ideas on how to improve it!""";
        width = content.measure.w,
    )
    hline = hLine(content.measure.w; style = indigo * " dim")
    content = content / hline / second_message

    # add a final message
    msg = """{#75b6e0}Term.jl is based on the {underline}Python{/underline} library {orange1 italic}Rich{/orange1 italic} by {/#75b6e0}Will McGugan. 
                        {dim}https://github.com/Textualize/rich{/dim}"""

    logo =
        Panel(
            content;
            title = "Term.jl",
            title_style = "bold $indigo",
            style = "dim $indigo",
            subtitle = "https://github.com/FedeClaudi/Term.jl",
            subtitle_justify = :right,
            subtitle_style = "dim",
            fit = false,
        ) / "" / (Spacer(2, 12) * msg)

    return logo
end

print(make_logo())
