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