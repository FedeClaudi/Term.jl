using Term
import Term.Renderables: Renderable
import Term: rint
import Term: inspect
using Term.Layout
import Term.Measures: height

import MyterialColors: orange_light, blue_light, green_light

"""
Convert HSL values to RGB values, return a markup color string.
"""
function hsl2rgb(h, s, l)  # pragma: no cover
    C = (1 - abs(2 * l - 1)) * s
    X = C * (1 - abs(mod(h / 60, 2) - 1))
    M = l - C / 2

    if 0 ≤ h < 60
        r, g, b = C, X, 0
    elseif 60 ≤ h < 120
        r, g, b = X, C, 0
    elseif 120 ≤ h < 180
        r, g, b = 0, C, X
    elseif 180 ≤ h < 240
        r, g, b = 0, X, C
    elseif 240 ≤ h < 300
        r, g, b = X, 0, C
    elseif 300 ≤ h ≤ 360
        r, g, b = C, 0, X
    end

    r = (Int ∘ round)((r + M) * 255)
    g = (Int ∘ round)((g + M) * 255)
    b = (Int ∘ round)((b + M) * 255)

    return "($r, $g, $b)"
end

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
        RenderableText(circle; style = "#389826 bold");
        fit = true,
        style = "dim #389826",
        justify = :center,
        padding = (2, 2, 0, 0),
        title = "Made",
        title_style = "default bold red",
    )
    red = Panel(
        RenderableText(circle; style = "#CB3C33 bold");
        fit = true,
        style = "dim #CB3C33",
        justify = :center,
        padding = (2, 2, 0, 0),
        subtitle = "with",
        subtitle_style = "default bold #b656e3",
        subtitle_justify = :right,
    )
    purple = Panel(
        RenderableText(circle; style = "#9558B2 bold");
        fit = true,
        style = "dim #9558B2",
        justify = :center,
        padding = (2, 2, 0, 0),
        subtitle = "Term",
        subtitle_style = "default bold #389826",
    )

    hspacer = Spacer(green.measure.h, green.measure.w / 2 + 1)
    line = Spacer(1, green.measure.w * 2 + 6)
    circles =
        line / (hspacer * green * hspacer) / (red * Spacer(purple.measure.h, 2) * purple)
    return circles
end

function make_rgb_colors(; max_width = 88)
    colors = ""

    for y in 0:5
        for x in 0:max_width
            h = x / max_width
            l = 0.1 + (((5 - y) / 5) * 0.7)
            color = hsl2rgb(h * 360, 0.9, l)
            bg = hsl2rgb(h * 360, 0.9, l + 0.7 / 10)

            colors *= "{$color on_$bg}▄{/$color on_$bg}"
            # colors *= "{$color on_$bg}▬▄x{/$color on_$bg}"
        end
        colors *= "\n"
    end

    return colors
end

function rainbow_maker(N)
    R = range(30, 200; length = N)
    G = range(200, 60; length = N)
    B = range(50, 200; length = N)
    colors = []
    for n in 1:N
        r, g, b = rint(R[n]), rint(G[n]), rint(B[n])
        push!(colors, "($r,$g,$b)")
    end
    return colors
end

circles = make_julia_circles() # 42 x 17

_code_style = "yellow italic bold"

bfc = rainbow_maker(10)
basic_features = Panel(
    """
    {bright_red bold underline}Features{/bright_red bold underline}

{bold $(bfc[1])}✔{/bold $(bfc[1])}{white} {blue}Colored text{/blue}{/white}
{bold $(bfc[2])}✔{/bold $(bfc[2])}{white} {italic}italic{/italic}, {bold}bold{/bold}, {underline}underline{/underline}, {striked}striked{/striked}, {inverse}inverse{/inverse}{/white}
{bold $(bfc[3])}✔{/bold $(bfc[3])}{white} styling {$_code_style}@macros{/$_code_style}{/white}
{bold $(bfc[4])}✔{/bold $(bfc[4])}{white} {italic white}markup{/italic white} style syntax{/white}
{bold $(bfc[5])}✔{/bold $(bfc[5])}{white} progress bars{/white}
{bold $(bfc[6])}✔{/bold $(bfc[6])}{white} Code introspection and REPR
{bold $(bfc[7])}✔{/bold $(bfc[7])}{white} logging{/white}
{bold $(bfc[8])}✔{/bold $(bfc[8])}{white} stacktraces{/white}
{bold $(bfc[9])}✔{/bold $(bfc[9])}{white} syntax highlighting{/white}
{bold $(bfc[10])}✔{/bold $(bfc[10])}{white} Markdown parsing{/white}
""";
    width = 70,
    padding = (2, 2, 1, 2),
    justify = :center,
    style = "default blue dim",
    title = "Term.jl",
    title_style = "default bright_blue bold",
    subtitle = "https://github.com/FedeClaudi/Term.jl",
    subtitle_style = "default dim",
    subtitle_justify = :right,
)

colors_info = TextBox(
    """{bold bright_green}Colors{/bold bright_green}
      {$(green_light) bold}✔{/$(green_light) bold} 8-bit colors
      {$(green_light) bold}✔{/$(green_light) bold} 16-bit colors
      {$(green_light) bold}✔{/$(green_light) bold} hex colors
      {$(green_light) bold}✔{/$(green_light) bold} rgb colors
      {$(green_light) bold}✔{/$(green_light) bold} colors conversion
    """;
    width = 25,
    padding = (0, 0, 0, 0),
)
colors = make_rgb_colors(; max_width = 103)

_lorem = """朗眠裕安無際集正聞進士健音社野件草売規作独特認権価官家複入豚末告設悟自職遠氷育教載最週場仕踪持白炎組特曲強真雅立覧自価宰身訴側善論住理案者券真犯著避銀楽験館稿告
"""
lorem_description = TextBox(
    """{bold bright_yellow}Text reshaping{/bold bright_yellow}
      {$(orange_light) bold}✔{/$(orange_light) bold} reshaping.
      {$(orange_light) bold}✔{/$(orange_light) bold} justification
      {$(orange_light) bold}✔{/$(orange_light) bold} Asian languages support
    """;
    width = 30,
    padding = (0, 0, 0, 0),
)
lorem1 = TextBox(_lorem; width = 62, fit = false, padding = (0, 0, 0, 0))
lorem2 = TextBox(_lorem; width = 42, fit = false, padding = (0, 0, 0, 0))

expr = :(2x + 2π / θ)
tree = Renderable(sprint(Tree, Float64))
dendo = Renderable(sprint(inspect, expr))
renderables_info = TextBox(
    """{bold bright_blue}Renderables types{/bold bright_blue}
      {bold $(blue_light)}✔{/bold $(blue_light)} Panel
      {bold $(blue_light)}✔{/bold $(blue_light)} TextBox
      {bold $(blue_light)}✔{/bold $(blue_light)} hLine
      {bold $(blue_light)}✔{/bold $(blue_light)} vLine
      {bold $(blue_light)}✔{/bold $(blue_light)} Tree
      {bold $(blue_light)}✔{/bold $(blue_light)} Dendogram


    """;
    width = 30,
    padding = (0, 0, 0, 0),
)

line = hLine(140; style = "bold dim grey35", box = :HEAVY)

layout_text = TextBox(
    """{bold bright_cyan}Renderables layout{/bold bright_cyan}
      {bold bright_cyan}✔{/bold bright_cyan} Horizontal stacking
      {bold bright_cyan}✔{/bold bright_cyan} Vertical stacking
      {bold bright_cyan}✔{/bold bright_cyan} Left justify
      {bold bright_cyan}✔{/bold bright_cyan} Center justify
      {bold bright_cyan}✔{/bold bright_cyan} Right justify
      {bold bright_cyan}✔{/bold bright_cyan} Shorthands {bold bright_blue}*,/{/bold bright_blue}
    """;
    width = 30,
    padding = (0, 0, 0, 0),
)

p1 = Panel(; width = 20, style = "#80bbe8")
p1b = Panel(; width = 34, style = "#80bbe8")
p2 = Panel(; width = 28, style = "#5692bf")
p3 = Panel(; width = 34, style = "#316c99 bold")
p3b = Panel(; width = 20, style = "#316c99 bold")
_space = Spacer(layout_text.measure.h, 1)

layout_example =
    hstack(lvstack(p1, p2, p3), cvstack(p1b, p2, p3b), rvstack(p1, p2, p3); pad = 1)

layout_example = cvstack(
    "" / RenderableText(
        "{bold #81bae6} Left/center/right justify and stack renderables to create layouts",
    ),
    layout_example,
)

using Markdown
import MyterialColors:
    pink_light, deep_purple_light, indigo_light, amber_light, teal_light, salmon_light
import Term.TermMarkdown: parse_md
styles =
    (pink_light, teal_light, indigo_light, amber_light, deep_purple_light, salmon_light)
rens =
    map(
        s -> Panel(; width = 20, height = 8, box = :SQUARE, background = "on_$s"),
        styles,
    ) |> collect
g = grid(rens)

t = parse_md(
    md"""
# Markdown parsing

Term parses `MD` types - markdown content - with style!

!!! tip "Docs"
    Have a look at the docs for more info!
    [docs](https://fedeclaudi.github.io/Term.jl/stable/)

Julia's docstring are parsed as Markdown, and Term turns markdown into styled terminal output. 
So you can use term to print styled docstrings and other info to the REPL. 

```julia
import Term: termshow

termshow(print)  # prints styled docstring to console
```

---
| Col1 | Col2 | Col3 | Col4 |
|:---------- | :----------: |:------------:|:------------:|
| ONE    | TWO |   THREE           |      FOUR        |
| ONE    | TWO  | THREE | FOUR|


!!! tip "Tables"
        The table above was parsed from a markdown to a `Table` renderable
        Term has a really awesome `Table` renderable, you should check it out!


""";
    width = 100,
)

# ----------------------------------- print ---------------------------------- #
# width is 140
print("\n"^10)

readme =
    (
        Spacer(circles.measure.h, 10) *
        circles *
        Spacer(circles.measure.h, 8) *
        basic_features
    ) / (Spacer(2, 140) / line) / (
        Spacer(colors_info.measure.h, 3) *
        colors_info *
        Spacer(colors_info.measure.h, 3) *
        (Spacer(1, 100) / colors)
    ) / line /
    (Spacer(lorem_description.measure.h, 3) * lorem_description * lorem1 * lorem2) / line /
    (
        Spacer(tree.measure.h, 3) *
        renderables_info *
        tree *
        Spacer(tree.measure.h, 5) *
        dendo
    ) / line / (Spacer(layout_text.measure.h, 3) * layout_text * layout_example) / line / (
        Spacer(height(t), 20) *
        vLine(height(t); style = "dim") *
        "  " *
        t *
        "  " *
        vLine(height(t); style = "dim")
    )

print(Spacer(readme.measure.h, 10) * readme)
