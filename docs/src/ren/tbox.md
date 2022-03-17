## TextBox
`TextBox`es are a very simple but very useful renderable. They bring together `RenderableText` with `Panel`.
In fact they're just a panel with a some text inside and with its box hidden. 
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