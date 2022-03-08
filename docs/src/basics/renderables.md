# Renderables
In the previous section we...
```@example
using Term  # hidden
tprint("[green]...have seen how to add some [gold3 bold underline]style[/gold3 bold underline] to our text")  # hidden
```

and that's great, but it's not enough. If you want to create really beutiful and structured terminal outputs, a bit of color and bold text is not enough. You want to be able to create panels to separate different pieces of content, lines to mark out different sections, you want to be able to control the aspect (e.g.,, line length) of the content you're printing and, most importantly, you want to do all this without too many headaches. `Term.jl` has got your back.

In this section we will look at `Renderable` objects (subtypes of `AbstractRenderable`) such as `TextBox` and `Panel`. In the next page we will focus on how to compose multiple renderables into a layout and we'll introduce renderables such as `hLine` and `Spacer` that are best introduced in that context.

## AbsractRenderable
This section focuses a bit on how renderables work under the hood. If you just want use `Term` and you don't care too much for how it works, skip ahead to the next section!

When you venture beyond styling simple strings, virtually every object you'll encounter will be a subtype of the `AbstractRenderable`. We will call these objects renderables. Renderable types vary, but they all must have two fields: `:segments` and `:measure`.

!!! note "Segment & Measure"
    A `Segment` is simply a line of text, kinda. The segment type:
    ```Julia
        struct Segment
            text::AbstractString   # text with ANSI codes injected
            plain::AbstractString  # plain text with no style
            measure::Measure       # measure of plain text
        end
    ```

    stores a bit of plain text (i.e. without any style information) but also the same text with style information (`text`). Text is created as described earlier, using `apply_style`. The other bit of information is the `Measure` object. `Measure` keeps track of the size of objects as they will be rendered in the terminal (i.e., wihtout style markup or ANSI codes). It sores a width (`w`) and height (`h`) attribute keeping track of text width and number of lines. The `Measure` of a segment is just that: the `textwidth` of `Segment.plain` and the number of lines in it. 

    When creating a renderable. This will generally produce the content that will be ultimately be printed to te terminal by generating a list of `Segment`s. When the renderable is printed out, its `Segment.text`s are printed to the console in sequence. The `Measure` of a renderable is a combination of the `Measure` of the individual segments. It provides information about the renderable's width and number of lines, crucial when creating layouts!


## Renderable
The most generic renderable type is the creatively named `Renderable`. You'll very rarely create an instance of a `Renderable` from scratch. More generally `Term` will create one while performing another operation. For example: in the next page we'll see how to stack multiple renderables to crate a complex layout. Each renderable can be any `AbstractRenderable`-like object (including string). So if you're stacking a `Panel`, a `TextBox` an a `String`, what type should the resulting renderable object be? Well the generic but useful `Renderable` of course. 


## RenderableText
Now we get to more interesting stuff: `RenderableText`. What is it? Exactly what the name says, a renderable that stores a bit of text:
```@example
using Term # hide
rend = RenderableText("""
    [bold red]Woah, my first [yellow italic]`Renderable`!
""")
print(rend)
```

Nothing special here. You'll notice that `RenderableText` automatically applies style information though. Also, when we were just styling strings before we had to use `tprint` instead of the normal `print` function to get our styled output. Well no more! `Renderable` objects work well with `print` so you can drop that `t`. 

Now, do we really need a whole new type just to print a bit of text? Of course not, but `RenderableText` does more than that!

```@example
import Term: RenderableText

rend = RenderableText("."^100; width=25)
print(rend)
```

magic! When we pass a width argument `RenderableText` reshapes our input text to the desired width! As you can imagine, when you're creating a layout made up of multiple elements, you want to be able to control the width of each element, so here you go!

Now, as a reward for getting this far into the docs, a little sneak preview at renderables stacking:


```@example
import Term: RenderableText # hide

lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." # hide

t1 = RenderableText(lorem; width=25)
t2 = RenderableText(lorem; width=42)
rend = t1 / "\n [bold green]second paragraph[/bold green] \n" / t2  # stacking syntax!!! - the result is typeof `Renderable`
print(rend)
```

## Panel
Okay, time to move beyond simple text. It's time for:
```@example
import Term: Panel # hide

print(
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
) # hide
```

Simpli put, a `Panel` showing a piece of content (generally a styled string, but it can be any `Renderable` really) surrounded by a box. Simple but effective.

Well not that simple actually because `Panel` is the first renderable that allows you lots of options to personalize its appearance. For instance the panel printed above is given by:
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



By the way, `Panels` are not limited to having strings as content, they can have other renderables too (multiple ones in fact)!
```@example

import Term: Panel # hide

print(
    Panel(
        Panel(width=18, style="green"),
        Panel(width=18, style="white"),
        Panel(width=18, style="red"),
        title="so many panels!",
        width=:fit,
        title_justify=:left,
        title_style="bold red"
    )
)
```


## TextBox
`TextBox`es are a very simple but very useful renderable. They bring together `RenderableText` with `Panel`.
In fact they're just a panel with a `RenderableText` inside and with its box hidden. 
Why do we need them, you say? Well because now you can have a piece of text, with a nice title and sub title.

```@example
import Term: TextBox

print(
    TextBox(
        ","^100 * "\n",
        title="title!",
        subtitle="sub title!",
        width=30,
        title_style="bold red",
        subtitle_style="dim",
        title_justify=:center,
    )
)
```

Okay, admittedly that's not huge. But it still nice to have. It also helps with keeping layout consistent when mixing panels and text, have a look:

```@example
import Term: RenderableText, Panel

t = ","^100

text = RenderableText(t; width=22)
panel = Panel(t, width=22)


print(
    text, panel
)
```
you see? The panel and the text have the same width, BUT, the panel must fit its box, some padding *and* its content within the same width. So the size of the text inside will need to change compared to `RenderableText(t; width=22)`. If we use a `TextBox` on the other hand:

```@example

import Term: TextBox, Panel # hide

t = ","^100 # hide

tbox = TextBox(t, width=22)
panel = Panel(t, width=22)

print(
    tbox, panel
)
```
Now the two pieces of text look the same and the final layout is a lot more homogeneous, success!

Let's move on to talk about layout more!