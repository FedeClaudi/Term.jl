# [Panel](@id PanelDocs)
Okay, time to move beyond simple text. It's time for:
```@example
import Term: Panel # hide
print(# hide
    Panel(# hide
        "[red]awesome[/red]", # hide
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

Well not that simple actually because [`Term.panel.Panel`](@ref) is the first renderable that allows you lots of options to personalize its appearance. For instance the panel printed above is given by:
```julia
    Panel(
        "[red]awesome[/red]",
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
```@example

import Term: Panel # hide

print(
    Panel(width=8, box=:DOUBLE, style="green") *
    Panel(width=8, box=:HEAVY, style="white") *
    Panel(width=8, box=:ROUNDED, style="red"),
)
```


Let's look at some more examples:
```@example

import Term: Panel # hide

print(
    Panel("this panel has fixed width, text on the left"; width = 66, justify = :left),    
    Panel("this one too, but the text is at the center!"; width = 66, justify = :center),
    Panel("the text is here!"; width = 66, justify = :right),
)
print("\n")

# padding!
print(
    Panel("content "^10; fit=true, padding=(0, 0, 0, 0)),
    Panel("content "^10; fit=true, padding=(4, 4, 0, 0)),
    Panel("content "^10; fit=true, padding=(2, 2, 2, 2)),
)
```

By the way, `Panels` are not limited to having strings as content, they can have other renderables too (multiple ones in fact)!
```@example

import Term: Panel # hide

print(
    Panel(
        Panel(width=18, style="green"),
        Panel(width=18, style="white"),
        Panel(width=18, style="red"),
        title="so many panels!",
        fit=true,
        title_justify=:left,
        title_style="bold red"
    )
)
```

## Size & fitting
By default `Panel`s are created to be 88 in width (or less if you have a small terminal) and as high as required to fit your content (+2 for the top and bottom line). If you content is narrowe than the panel's width, then all is good (and you can use `justify` to place it as you like). If not, there's two options: reshape your text to fit in the panel or enlarge the panel to envelop your content. The first is used when the content is a text type, the latter if its another renderable:

```@meta
CurrentModule = Term
```
```@example

import Term: Panel

reshaped = Panel("very long text"^25)

print(
    reshaped,
    Panel(reshaped)
)
```

If you want to though, you can set the size to be whatever you like:
```@example
import Term: Panel # hide

print(
    Panel(; width=22, height=9)
)
```

Sometimes though, you just want your panel to snugly envelop your content without extra space and without having to specify the width. Easy:

```@example
import Term: Panel  # hide

p = Panel(; width=22, height=4)
print(
    Panel(p; fit=true)
)
```

## Padding
You'll notice in the example above that there's still some space around our nested panel, even though we wanted `fit=true`, why is that? Well, `Panel` by default applies some `Padding` around your content. You can control how much padding you want:
```@example
import Term: Panel # hide

p = Panel(; width=22, height=4) # hide
print(
    Panel(p; fit=true, padding=(0, 0, 0, 0)),
    Panel(p; fit=true, padding=(3, 3, 3, 3)),
)
```

The syntax is `(left, right, top, bottom)` and the default is `(2, 2, 0, 0)`.