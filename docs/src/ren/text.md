# [RenderableText](@id RtextDoc)
`RenderableText`, what is it? Exactly what the name says: a renderable that stores a bit of text:
```@example
using Term # hide
rend = RenderableText("""
{bold red}Woah, my first {yellow italic}`Renderable`!
""")
print(rend)
```

Nothing special here. You'll notice that `RenderableText` automatically applies style information though. Also, when we were just styling strings before we had to use `tprint` instead of the normal `print` function to get our styled output. Well no more! `Renderable` objects work well with `print` so you can drop that `t` (when printed renderables print their `Segmen`s remember? `Segment`s already store style information). 

Now, do we really need a whole new type just to print a bit of text? Of course not, but `RenderableText` does more than that!

```@example
import Term: RenderableText

print(RenderableText(","^100; width=25))
print("\n"^2)
print(RenderableText(","^100; width=50))
```

magic! When we pass a width argument `RenderableText` reshapes our input text to the desired width! As you can imagine, when you're creating a layout made up of multiple elements, you want to be able to control the width of each element, so here you go! 

Admittedly this is not huge, but it can come in handy sometimes. More importantly, the behavior of `RenderableText` also give you an idea of what happens to your strings when you put them in a `Panel` or `TextBox` renderable, so let's look at them!