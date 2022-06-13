# Renderables
In the previous section we...
```@example
using Term  # hidden
tprint("{green}...have seen how to add some {gold3 bold underline}style{/gold3 bold underline} to our text")  # hidden
```

and that's great, but it's not enough. If you want to create really beautiful and structured terminal outputs, a bit of color and bold text is not enough. You want to be able to create panels to separate different pieces of content, lines to mark out different sections, you want to be able to control the aspect (e.g. line length) of the content you are printing and, most importantly, you want to do all this without too many headaches. `Term.jl` has got your back.

In this section we will look at `Renderable` objects (subtypes of `AbstractRenderable`) such as `TextBox` and `Panel`. Each type of renderable also has a dedicated pages under the section "Renderables" where the renderable is described more in detail. Here we will describe renderables in general, while in the coming section we'll talk about building layouts composed of multiple renderables. 


## AbstractRenderable
This section focuses a bit on how renderables work under the hood. If you just want use `Term` and you don't care too much for how it works, skip ahead to the next section!


When you venture beyond styling simple strings, virtually every object you'll encounter will be a subtype of the  [`AbstractRenderable`](@ref Term.Renderables.AbstractRenderable) type. We will call these objects renderables. Renderable types vary, but they all must have two fields: [`Segment`](@ref Term.Segments.Segment) and [`Measure`](@ref Term.Measures.Measure):


A `Segment` is roughly equivalent to one line of text. Let's take something like this (printed out in your terminal):
```
╭────────────────────╮
│                    │
╰────────────────────╯
```
you can think of this as being made of three segments:
```
# 1
╭────────────────────╮

# 2
│                    │

# 3
╰────────────────────╯
```

When the renderable get's printed each of its segments is printed separately on a new line, giving the illusion of a single object (if we designed the segments correctly). 
In addition, the text stored by a `Segment` already has applied style information to it (i.e. markup tags are converted to ANSI codes), so it's ready to print!

In addition to a vector of segments, a renderable is defined by a `Measure` object. Roughly speaking, a `Measure` object stores information about the size of a renderable **as it will appear in the terminal**. Anything can have a measure: a string of text, a segment (the measure of its text) and a renderable (the combined measure of its segments). This information is crucial when we start putting multiple renderables together. For instance the renderable shown above is a [Panel](@ref PanelDocs) and a `Panel` can be created to fit a piece of text:

```@example
import Term: Panel

print(Panel("this is {red}RED{/red}"; fit=true))
```

in order to do that `Panel` needs to know the size of the text it needs to fit, and that's done by taking its measure (note that the measure correctly ignores the style information to get the size of the text as it will be when printed out).
Finally, we can think of the panel itself as having a `Measure=(17, 3)`: 17 is the width of the panel and 3 its height (the number of segments). Again, this information is crucial when creating layouts of multiple renderables:
```@example

import Term: Panel

print(Panel(;height=3, width=6) * Panel(; height=5, width=12))
```
but more on that in the next section. 


## Other renderables
`Term` comes with a few different types of renderables (we saw `Panel` already, but there's more), but the basic idea is that they are made of segments of text and have a measure. Each renderable has its own additional features on top of that, but those are described more in detail in dedicated pages (look left!).
Briefly, we have `Panel` which creates stuff like what we've just seen, [RenderableText](@ref RtextDoc) which handles rendering text in the console (surprise!) and [TextBox](@ref TBoxDoc) which is somewhat in between the two. Other renderables include things like [Tree](@ref TreeDoc) and, in the future, `Table`. Now lets look at how we can put multiple renderables together!

