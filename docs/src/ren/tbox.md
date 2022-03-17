# [TextBox](@id TBoxDoc)
`TextBox`es are a very simple but very useful renderable. They bring together the functionality of `RenderableText` with that of `Panel`.
In fact you can think of  just a panel with a some text inside and with its box hidden. 
Why do we need them, you say? Well because now you can have a piece of text, with a nice title and sub title.

```@example tbox
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

```@example tbox
import Term: RenderableText, Panel

t = ","^100

text = RenderableText(t; width=22)
panel = Panel(t, width=22)


print(
    text, panel
)
```
you see? The panel and the text have the same width, BUT, the panel must fit its box, some padding *and* its content within the same width. So the size of the text inside will need to change compared to `RenderableText(t; width=22)`. If we use a `TextBox` on the other hand:

```@example tbox

tbox = TextBox(t, width=22)
panel = Panel(t, width=22)

print(
    tbox, panel
)
```
Now the two pieces of text look the same and the final layout is a lot more homogeneous, success!


## Fitting and truncating
Like for panel, we have a few options on how we want the length of the text and the size of the textbox to look like. The simplest thing is specifying the width of the textbox, the text will be reshaped to fit in:

```@example tbox2
import Term: TextBox 
text = "x"^500

print(TextBox(text))
print(TextBox(text; width=44))
```

But we can also fit the box to the text. In that case the box will be as large as it needs to be (still fitting within your terminal window):

```@example tbox2
print(TextBox(text; fit=:fit))
```

and finally, we can truncate the text so that it's as wide at the box,  discarding what's left:

```@example tbox2

print(TextBox(text; fit=:truncate))
```