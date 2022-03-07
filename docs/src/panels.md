In the previous section we...
```@example
using Term  # hidden
tprint("[green]...have seen how to add some [gold3 bold underline]style[/gold3 bold underline] to our text")  # hidden
```

and that's great, but it's not enough. If you want to create really beutiful and structured terminal outputs, a bit of color and bold text is not enough. You want to be able to create panels to separate different pieces of content, lines to mark out different sections, you want to be able to control the aspect (e.g.,, line length) of the content you're printing and, most importantly, you want to do all this without too many headaches. `Term.jl` has got your back.

In this section we will look at `Renderable` objects (subtypes of `AbstractRenderable`) such as `TextBox` and `Panel`. In the next page we will focus on how to compose multiple renderables into a layout and we'll introduce renderables such as `hLine` and `Spacer` that are best introduced in that context.

## AbsractRenderable & Segments
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

    