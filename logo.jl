import IterTools: product as ×

import Term: Panel, RenderableText
import Term: vstack, hstack

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
   style="dim #389826", 
   justify=:center,
   title="[italic]Made", 
   title_style="bold red"
   )
red = Panel(
   RenderableText(circle, "#CB3C33 bold"),
   style="dim #CB3C33",
   justify=:center,
   subtitle="[italic]with", 
   subtitle_style="bold #b656e3",
   subtitle_justify=:right,
)
purple = Panel(
   RenderableText(circle, "#9558B2 bold"), 
   style="dim #9558B2", 
   justify=:center, 
   subtitle="[italic]Term", 
   subtitle_style="bold #389826"
)


indigo = "#42A5F5"
main = Panel(
"""   [bold $indigo underline]Term.jl[/]

Presenting [italic $indigo]Term[/], a fancy terminal library.

Style your text: [bold]bold[/],[italic]italic[/],[underline]underlined[/].
[magenta2]You[/] [pink3]can[/] [bright_blue]add[/] [spring_green2]some[/] [green_yellow]color[/] [sky_blue2]too[/][bold bright_red]![/]

Or create [italic bold light_sky_blue1]Panels[/] and [italic bold light_sky_blue1]RenderableTexts[/], and
[italic bold]stack[/] them to create 
[italic]structured, [light_goldenrod3]fancy[/][/], terminal output.



   [dim]https://github.com/FedeClaudi/Term.jl""",
style="hidden",
subtitle="vX.X", 
subtitle_justify=:right, 
subtitle_style="dim"
)

# create "spacers"
hspacer = RenderableText(join([" "^(Int(round(green.measure.w/2))) for i in 1:green.measure.h], "\n"))



circles = vstack(
   hstack(hspacer, green, hspacer),
   hstack(red,purple)
)
vspacer = RenderableText(join([" "^3 for i in 1:circles.measure.h], "\n"))

logo = Panel(hstack(
   circles, vspacer, main
), title="Term.jl", title_style="bold $indigo", style="dim $indigo"
)
print(logo)

# circles = vstack(green, red)

# print(circles)

