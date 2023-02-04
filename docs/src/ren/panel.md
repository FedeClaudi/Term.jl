# [Panel](@id PanelDocs)
Okay, time to move beyond simple text. It's time for:
```@example
import Term: Panel # hide
print(# hide
    Panel(# hide
        "{red}awesome{/red}", # hide
        title="Term's", # hide
        title_style="bold green", # hide
        style="gold1 bold", # hide
        subtitle="Panels", # hide
        subtitle_style="bold blue", # hide
        subtitle_justify=:right, # hide
        width=18, # hide
        justify=:center # hide
    ) # hide
) # hide
```

Simply put, a `Panel` shows a piece of content (generally a styled string, but it can be any `Renderable` really) surrounded by a box. Simple but effective.

Well not that simple actually because [`Term.Panels.Panel`](@ref) is the first renderable that allows you lots of options to personalize its appearance. For instance the panel printed above is given by:
```julia
    Panel(
        "{red}awesome{/red}",
        title="Term's",
        title_style="bold green",
        style="gold1 bold",
        subtitle="Panels",
        subtitle_style="bold blue",
        subtitle_justify=:right,
        width=18,
        justify=:center
    )
```

The first argument is the content, the rest is styling options. As you can see you can specify the titles and subtitles (or leave them out if you prefer, do your thing!), their appearance (via `markup` style information) and their position (`:left, :center` or `:right`). The `style` argument sets the style of the box itself (and title/subtitle if they don't have dedicated style information).

The box is created using `Term`'s own `Box` type! It's not worth going too much into exactly how it works, but it's worth pointing out that there's loads of types of boxes:
```
ASCII,
ASCII2,
ASCII_DOUBLE_HEAD,
SQUARE,
SQUARE_DOUBLE_HEAD,
MINIMAL,
MINIMAL_HEAVY_HEAD
MINIMAL_DOUBLE_HEAD,
SIMPLE,
SIMPLE_HEAD,
SIMPLE_HEAVY,
HORIZONTALS,
ROUNDED,
HEAVY
HEAVY_EDGE,
HEAVY_HEAD,
DOUBLE,
DOUBLE_EDGE
```

And you can use any of these with your panels:
```@example panel
import Term: Panel

print(
    Panel(width=8, box=:DOUBLE, style="green") *
    Panel(width=8, box=:HEAVY, style="white") *
    Panel(width=8, box=:ROUNDED, style="red"),
)
```


Let's look at some more examples:
```@example panel

print(
    Panel("this panel has fixed width, text on the left"; width = 66, justify = :left),    
    Panel("this one too, but the text is at the center!"; width = 66, justify = :center),
    Panel("the text is here!"; width = 66, justify = :right),
)
print("\n")
```
You can justify the panel's content to `:left, :center, :right`!

```@example panel
    Panel("Titles have style too!!"; width = 60, justify = :center, title="My Title", title_style="red bold", title_justify=:right, subtitle="Made with Term", subtitle_style="dim", subtitle_justify=:left
)
```
And style the title and subtitle, or the whole background too:
```@example panel
import Term: highlight_syntax

Panel(
    highlight_syntax("""
function show_off(x)
    print(x)
end
"""); 
    background="on_black", fit=true, style="on_black"
)

```

By the way, `Panels` are not limited to having strings as content, they can have other renderables too (multiple ones in fact)!
```@example panel
Panel(
        Panel(width=18, style="green"),
        Panel(width=18, style="white"),
        Panel(width=18, style="red"),
        title="so many panels!",
        fit=true,
        title_justify=:left,
        title_style="bold red"
    )

```

## Size & fitting
By default `Panel` tries to fit your content:

```@example panel
print(Panel("."^10))
print(Panel("."^30))
print(Panel("."^60))
```

but you can change this by passing a `width` value. In fact you can se a height too:
```@example panel
Panel("."^10; height=5, width=20)
```

Alternatively, you can use `fit=false`. 
```@example panel
Panel("."^10; fit=false)
```
this will make all panels have the same width (unless you specify a width). The main difference is that if the content is larger than the panel, it will be truncated, which is not what happens if `fit=true`"
```@example panel
p1 = Panel("."^10; height=5, width=60)
print(Panel(p1; height=2, width=30))  # fit=true -> expand out panel, width/height ignored
print(Panel(p1; height=10, width=30, fit=false))  # fit=false -> truncate the content
print(Panel("very long text"^20; height=10, width=30, fit=false))  # text is reshaped to fit the panel
```


## Padding
You'll notice in the example above that there's still some space between the panel's borders and its content. That's padding. You can change how much padding to have to the left, right, top and bottom (in number of spaces/lines):

```@example panel
inner = Panel(height=4, width=8, background="on_#262626", style="bold red")
print(
    Panel(inner; fit=false, padding=(0, 0, 0, 0)),
    Panel(inner; fit=false, padding=(3, 1, 3, 1)),
    Panel(inner; fit=false, padding=(20, 3, 3, 1)),
)
```

The syntax is `(left, right, top, bottom)` and the default is `(2, 2, 0, 0)`.


# [TextBox](@id TBoxDoc)
Sometimes you want to have the benefits of `Panel` (you can control the height, width, padding, justification, titles...) without actually showing the panel itself. Introduce: `TextBox`.
```@example
using Term: TextBox
TextBox("A very long piece of text"^10; title="TEXT", width=30, fit=false)
```

Easy peasy!