# [Content layout](@id content_layout)
Okay, so we can style text and we can create fancy panels. Cool. Not enough. If we want to get **real fancy** we need to combine multiple renderable elements. Like this:

```@example
import Term
print(Term.make_logo())
```

The example above is composed of panels and textboxes, of course, but also additional lines and spacing elements that can help with the layout. These elements are combined using a very simple syntax to create the whole thing.

## Nesting
The easiest way to create a layout is to nest things. We've already briefly seen how to do this with `Panel`s:
```@example

import Term: Panel # hide

print(
    Panel(
        Panel(
            Panel(
                "We need to go deeper...",
                height=3,
                width=28,
                style="green",
                box=:ASCII,
                title="ED",title_style="white",
                justify=:center
            ),
            style="red", box=:HEAVY, title="ST", title_style="white", fit=true
        ),
        width=44, justify=:center, style="blue", box=:DOUBLE, title="NE", title_style="white"
    )
)
```

That's all there is really. `Panel` can take one or multiple string and `AbstractRenderable` objects as argument and stacks them inside. You can combine this with the `width`, `height` and `justify` argument to mix things up, but simple nesting will only take you so far. We need better way to compose a layout.

## Stacking
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
    (p * p * p) / (p * (p/p)) / (p * p * "[bold red]supripse![/bold red]")
)
```


what's that red text doing in there? We didn't use `tprint`, or `apply_style`, we didn't put it into a [`RenderableText`](@ref RtextDoc) or a [`TextBox`](@ref TBoxDoc) (see [Renderables](@ref RenIntro))... why didn't it print as `"[bold red]supripse![/bold red]"`??

The answer is that stacking operators return the generic `Renderable` type object, and `Renderable`s apply their styles before printing out to console. Okay, not a huge surprise I guess, but I just wanted an excuse to say that regardless of what goes into `*` and `/` the output is a generic `Renderable` (well with the exception of `*` between two strings which returns a string; also `*` and `/` don't work with things like `::Number` & co., but you get the idea). The reason for the generic `Renderable` type is that the product of two stacked renderables should act as a unitary single renderable in its own right. You should be able to print it, stack it etc... So `Renderable` is the simplest type of renderable that can do this (it only has segments and measure, no other features - see previous section), so when we stack together multiple different types of renderables we create a generic container. 

Previously we briefly mentioned the idea of the `Measure` or a renderable object. `Measure` stores information about the width and height of a renderable as it will appear in the terminal. When we stack renderables, the `Measure` of the resulting `Renderable` will do the following:
- if we are using `*` the width will be the sum of widths of the two renderables and the height will be the height  of the tallest renderable
-  if we are using `/` the width will be that of the widest renderable and the height will be the sum of heights. 

Let's see:
```@example
import Term: Panel # hide
p1 = Panel(width=5, height=5)
println("p1.measure: ", p1.measure)


p2 = Panel(width=8, height=5)
println("p2.measure: ", p2.measure)

h = p1 * p2
println("* stacked measure: ", h.measure)

v = p1 / p2
println("/ stacked measure: ", v.measure)
```

This is important, because often you want to know a `Renderable`'s size when creating a layout, as we'll see next.


## Justify
When dealing with renderables width different widths, you can "justify" them: create renderables with the same width and with the content aligned to the left or right or to the center. 
It's easiest to see what we're talking about with an example:


```@example justify
using Term # hide

p1 = Panel(; width=25)
p2 = Panel(; width=50)
print(p1/p2)
```

What's happening is that the two panels have different sizes:
```@example justify
p1
```

```@example justify
p2
```

And when they get stacked together they form a single `Renderable` object with the right size by padding the smaller renderable on the right:
```@example justify
p1/p2
```

That's okay if we want our conent to be left-aligned, but if we want it to be center- or right- aligned we need to first justify our content and then stack:
```@example justify
center!(p1, p2)

p1
```
As you can see, calling `center!` modified our panel so that it has the same width as `p2`. The crucial point is that when using `center!` the panel
is padded on both the left and the right, look what happens when we stack the panels now:
```@example justify
p1/p2
```

Eureka!

`Term` offers three "justification" functions: `leftalign!, center!, rightalign!` and their non-modifying counterparts: `leftalign, center, rightalign`.
The difference is that `center!(p1, p2)` modifies the two panels directly, `center(p1, p2)` returns two new panels.

Very frequently justification is done before stacking the panels. You could do:
```@example justify
using Term # hide

p1 = Panel(; width=25)
p2 = Panel(; width=50)
print(p1/p2)
```

but you can also use the convenience functions offered by Term:
```@example justify3
using Term # hide

p1 = Panel(; width=25)
p2 = Panel(; width=50)

cvstack(p1, p2)
```

`lvstack`, `cvstack` and `rvstack` do left/center/right justification first and then vertically stack the panels. They use the non-modifying version of the
justification functions so your original panels are not modified. Finally, you can also use `←, ↓, →` (using \leftarrow, \downarrow and \centerarrow) as shorthand for 
l/c/r-stack functions:

```@example justify3
using Term # hide

p1 = Panel(; width=5; style="green")
p2 = Panel(; width=10; style="white")
p2 = Panel(; width=15; style="red")

→(p1, p2, p3)
```

Pretty nifty huh?


## Spacer
Okay, we can stack two `Panel`s side by side. It looks like this:

```@example
using Term # hide

p = Panel(width=5, height=3)
print(p * p)
```

but what if we want some space between them? We can do something like
```@example
using Term # hide
p = Panel(" "; fit=true) # hide
print(p * " "^5 * p)
print(p / "\n"^2 / p)
```
to create horizontal and vertical spaces. But what if we want to separate two renderables by a space that is 4 characters wide and 3 lines high? We could create a string which does that and stack it with our renderables...
Doesn't sound fun. That's why `Term` has a `Spacer` renderable object that does it for your:
```@example
import Term: Panel # hide
import Term: Spacer
p = Panel(width=5, height=3) # hide

space = Spacer(5, 3; char=',')
print(p * space * p)
```

here we're using the optional argument `char` to fill the spacer with a character so that we can see what it looks like. Normally it would be just empty space. The nice thing about spacer is that we can easily do things like this:
```@example
import Term: Panel, Spacer # hide
p = Panel(width=5, height=3) # hide

top = p * Spacer(5, 3; char='t') * p
mid = Spacer(top.measure.w, 2; char='m') # use top's Measure info !
bottom = p * Spacer(5, 3; char='b') * p

print(top / mid / bottom)
```

look at that layout! Actually don't, look at it without that clutter:
```@example
import Term: Panel, Spacer # hide
p = Panel(width=5, height=3) # hide

top = p * Spacer(5, 5) * p
mid = Spacer(top.measure.w, 2) # use top's Measure info !
bottom = p * Spacer(5, 5) * p

print(top / mid / bottom)
```

## vLine
Space is nice. You can separate distinct pieces of content so that the message you're trying to convey is more easily interpreted by the user. But space is not enough. Sometimes you want to add a line to mark out where one section ends and the other starts.
Well, that's where `vLine` and `hLine` below come in. They're very simple to use, just say how tall/weide the line should be and, optionally, give some markup style information too:

```@example
import Term: Panel, Spacer # hide
import Term: vLine
p = Panel(width=5, height=3) # hide

l = vLine(p.measure.h; style="bold red")
s = Spacer(2, p.measure.h)

print(p * l * s * l * p)
```

!!! note
    Like with `Panel`, `vLine` and `hLine` accept a `box=` keyword argument with the `::Symbol` of any of the `Box` objects supported by `Term`.


## hLine
I think you can guess where we are going with this. `hLine` is just like `vLine` but horizontal:
```@example
import Term: Panel, Spacer # hide
import Term: hLine

p = Panel(width=5, height=3) # hide
l = hLine(20, "whaaat"; style="bold red", box=:DOUBLE)


print(p / l / p)
```

surprise! `hLine` is *not just like `vLine`*: it also accepts an optional text argument to create a little title line if you will. But yeah, otherwise it's just the same. 

