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

!!! note "Segment & Measure
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

## TextBox