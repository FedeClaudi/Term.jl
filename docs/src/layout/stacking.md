
# Stacking
The idea is simple: horizontally stack two renderables and they will appear side by side, stack them vertically and they will appear one over the other. The syntax is even simpler: `*` lets you horizontally stack (or concatenate strings) and `/` lets you stack them vertically.

!!! note
    The choice of `*` and `/` as operators for stacking operations was somewhat arbitrary.
    `*` was chosen because it's already what Julia uses to concatenate strings, and you can think of that as "horizontally stacking them". `/` was chosen because it reminds me of fractions, and fractions have one number over another. 

    If you don't like to use these operators, you're in luck! They are really just a 
    shorthand notation for the functions `hstack` & `vstack`. You'll find that this notation makes for some pretty nifty code though.

Let's stack things:

```@example

import Term: Panel # hide

println(
    Panel("horizontally"; fit=true) * Panel("stacked"; fit=true)
)
println("&\n")
println(
    Panel("vertically"; fit=true) / Panel("stacked"; fit=true)
)

```

As simple as that. But you can also go crazy if you like:

```@example

import Term: Panel # hide

p = Panel(width=5)
println(
    (p * p * p) / (p * (p/p)) / (p * p * "{bold red}supripse!{/bold red}")
)
```


what's that red text doing in there? We didn't use `tprint`, or `apply_style`, we didn't put it into a [`RenderableText`](@ref RtextDoc) or a [`TextBox`](@ref TBoxDoc) (see [Renderables](@ref RenIntro))... why didn't it print as `"{bold red}supripse!{/bold red}"`??

The answer is that stacking operators return the generic `Renderable` type object, and `Renderable`s apply their styles before printing out to console. Okay, not a huge surprise I guess, but I just wanted an excuse to say that regardless of what goes into `*` and `/` the output is a generic `Renderable` (well with the exception of `*` between two strings which returns a string; also `*` and `/` don't work with things like `::Number` & co., but you get the idea). The reason for the generic `Renderable` type is that the product of two stacked renderables should act as a unitary single renderable in its own right. You should be able to print it, stack it etc... So `Renderable` is the simplest type of renderable that can do this (it only has segments and measure, no other features - see previous section), so when we stack together multiple different types of renderables we create a generic container. 

Previously we briefly mentioned the idea of the `Measure` or a renderable object. `Measure` stores information about the width and height of a renderable as it will appear in the terminal. When we stack renderables, the `Measure` of the resulting `Renderable` will do the following:
- if we are using `*` the width will be the sum of widths of the two renderables and the height will be the height  of the tallest renderable
-  if we are using `/` the width will be that of the widest renderable and the height will be the sum of heights. 

Let's see:
```@example
import Term: Panel # hide
p1 = Panel(height=5, width=5)
println("p1.measure: ", p1.measure)


p2 = Panel(height=5, width=8)
println("p2.measure: ", p2.measure)

h = p1 * p2
println("* stacked measure: ", h.measure)

v = p1 / p2
println("/ stacked measure: ", v.measure)
```

This is important, because often you want to know a `Renderable`'s size when creating a layout, as we'll see next.

## vstack, hstack & padding
When stacking more than 2 renderables at one time, it's probably easier to use `vstack` or `hstack` than to use `*` and `/` directly:

```@example stacking
import Term.Layout: vstack, hstack # hide
import Term: Panel # hide
p1 = Panel(height=4, width=8) # hide

p1 * p1 * p1 * p1
```

can be written as:
```@example stacking
hstack(p1, p1, p1, p1)
```

which is easier to read. But more importantly. `vstack` and `hstack` let you define a padding (spacing) between the renderables being stacked:
```@example stacking
hstack(p1, p1, p1, p1; pad=8)
```
and 
```@example stacking
vstack(p1, p1, p1, p1; pad=1)
```

which is equivalent but much nicer than:
```@example stacking
space = " "^8  # or use Spacer
p1 * space * p1 * space * p1 
```

