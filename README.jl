using Term
import Term.renderables: Renderable
import Term: int
import Term.color: hsl2rgb

function make_julia_circles()
    circle = """
    oooo    
 oooooooooo 
oooooooooooo
oooooooooooo
 oooooooooo 
    oooo    """

    # create circles
    green = Panel(
        RenderableText(circle; style="#389826 bold");
        fit=true,
        style = "dim #389826",
        justify = :center,
        padding=(2, 2, 0, 0),
        title = "Made",
        title_style = "default bold red",
    )
    red = Panel(
        RenderableText(circle; style="#CB3C33 bold");
        fit=true,
        style = "dim #CB3C33",
        justify = :center,
        padding=(2, 2, 0, 0),
        subtitle = "with",
        subtitle_style = "default bold #b656e3",
        subtitle_justify = :right,
    )
    purple = Panel(
        RenderableText(circle; style="#9558B2 bold");
        fit=true,
        style = "dim #9558B2",
        justify = :center,
        padding=(2, 2, 0, 0),
        subtitle = "Term",
        subtitle_style = "default bold #389826",
    )

    hspacer = Spacer(green.measure.w / 2 + 1, green.measure.h)
    line = Spacer(green.measure.w * 2 + 6, 1)
    circles =  line / (hspacer * green * hspacer) / (red * Spacer(2, purple.measure.h) * purple)
    return circles

end


function make_rgb_colors(; max_width=88)
    colors = ""

    for y in 0:5
        for x in 0:max_width
            h = x / max_width
            l = 0.1 + (((5-y) / 5) * 0.7)
            color = hsl2rgb(h*360, .9, l)
            bg = hsl2rgb(h*360, .9, l + 0.7/10)

            colors *= "[$color on_$bg]▄[/$color on_$bg]"
        end
        colors *= "\n"
    end

    return colors
end


function rainbow_maker(N)
    R = range(30, 200, length=N)
    G = range(200, 60, length=N)
    B = range(50, 200, length=N)
    colors = []
    for n in 1:N 
        r, g, b = int(R[n]), int(G[n]), int(B[n])
        push!(colors, "($r,$g,$b)")
    end
    return colors
end


circles = make_julia_circles()  # 42 x 17

_code_style = "yellow italic bold"

bfc = rainbow_maker(8)
basic_features = Panel("""
    [bright_red bold underline]Features[/bright_red bold underline]

[$(bfc[1])]✔[/$(bfc[1])] [blue]Colored text[/blue]
[$(bfc[2])]✔[/$(bfc[2])] [italic]italic[/italic], [bold]bold[/bold], [underline]underline[/underline], [striked]striked[/striked], [inverse]inverse[/inverse]
[$(bfc[3])]✔[/$(bfc[3])] styling [$_code_style]@macros[/$_code_style]
[$(bfc[4])]✔[/$(bfc[4])] [italic white]markup[/italic white] style syntax
[$(bfc[5])]✔[/$(bfc[5])] progress bars
[$(bfc[6])]✔[/$(bfc[6])] [$_code_style]`Expr`[/$_code_style] and [$_code_style]`Type`[/$_code_style] introspection
[$(bfc[7])]✔[/$(bfc[7])] logging
[$(bfc[8])]✔[/$(bfc[8])] stacktraces
"""; width=70, padding=(2, 2, 2, 2), justify=:center, style="default blue dim",
title="Term.jl", title_style="bright_blue bold", 
subtitle="https://github.com/FedeClaudi/Term.jl", subtitle_style="default dim", subtitle_justify=:right
)


colors_info = TextBox(
"""[bold bright_green]Colors[/bold bright_green]
[bright_green bold]✔[/bright_green bold] 8-bit colors
[bright_green bold]✔[/bright_green bold] 16-bit colors
[bright_green bold]✔[/bright_green bold] hex colors
[bright_green bold]✔[/bright_green bold] rgb colors
[bright_green bold]✔[/bright_green bold] colors conversion
"""; width=25, padding=(0, 0, 0, 0))
colors = make_rgb_colors(;max_width=103)

_lorem = """朗眠裕安無際集正聞進士健音社野件草売規作独特認権価官家複入豚末告設悟自職遠氷育教載最週場仕踪持白炎組特曲強真雅立覧自価宰身訴側善論住理案者券真犯著避銀楽験館稿告
"""
lorem_description = TextBox(
"""[bold bright_yellow]Text reshaping[/bold bright_yellow]
[bright_yellow bold]✔[/bright_yellow bold] reshaping.
[bright_yellow bold]✔[/bright_yellow bold] justification
[bright_yellow bold]✔[/bright_yellow bold] Asian languages support
"""; width=28, padding=(0, 0, 0, 0))
lorem1 = TextBox(_lorem; width=62, padding=(0, 0, 0, 0))
lorem2 = TextBox(_lorem; width=44, padding=(0, 0, 0, 0))


expr = :(2x + 2π/θ)
tree = Renderable(sprint(typestree, Float64))
dendo = Renderable(sprint(inspect, expr))
renderables_info = TextBox(
"""[bold bright_blue]Renderables types[/bold bright_blue]
[bold bright_blue]✔[/bold bright_blue] Panel
[bold bright_blue]✔[/bold bright_blue] TextBox
[bold bright_blue]✔[/bold bright_blue] hLine
[bold bright_blue]✔[/bold bright_blue] vLine
[bold bright_blue]✔[/bold bright_blue] Tree
[bold bright_blue]✔[/bold bright_blue] Dendogram


[bold bright_cyan]Renderables layout[/bold bright_cyan]
[bold bright_cyan]✔[/bold bright_cyan] Horizontal stacking ([bold red]*[/bold red])
[bold bright_cyan]✔[/bold bright_cyan] Vertical stacking ([bold red]/[/bold red])

"""; width=28, padding=(0, 0, 0, 0)
)

line = hLine(140; style="bold dim grey35", box=:HEAVY)
# ----------------------------------- print ---------------------------------- #
# width is 140
print("\n"^3)

readme = (Spacer(10, circles.measure.h ) * circles * Spacer(8, circles.measure.h ) * basic_features) / 
(Spacer(140, 2) / line) /
(Spacer(3, colors_info.measure.h ) * colors_info * Spacer(3, colors_info.measure.h ) * (Spacer(100, 1 ) / colors)) /
line /
(Spacer(3, lorem_description.measure.h ) * lorem_description * lorem1 * lorem2 ) /
line /
(Spacer(3, tree.measure.h) * renderables_info * tree * Spacer(5, tree.measure.h) * dendo)

print(Spacer(10, readme.measure.h) * readme)