# Layout renderables

In this section we'll look at a few renderable types that are useful layout elements: they can be used to insert lines to demarcate different section, create some space or even as place holders for when you want to create a layout but don't have some content yet. 

!!! note "Layout syntax"
    Here we make use of the layout operators `*` and `/` to horizontally and vertically stack renderables. Have a look at the `Layout` section for more details!

## Spacer
`Spacer` creates a *box* of empty text with a given width and height. This can be useful for instance if you're stacking two other renderables but want some space between them:
```@example layout
import Term: Panel
import Term.Layout: Spacer

p = Panel(height=3, width=10)
space = Spacer(3, 5)
print(p * space * p)
print(p * p)
```

## Vertical line
`vLine` does one simple thing: creates a vertical line. You can style it and like for `Panel` you can use different `Boxes` to obtain different looks:
```@example layout

import Term.Layout: vLine
space = Spacer(10, 5)
vLine(10; style="red") * space * vLine(10; style="blue") * space * vLine(10; style="green", box=:DOUBLE)
```

and you can pass another `Renderable` as argument to create a line as tall as it:
```@example layout
import Term: Panel
p = Panel(height=3, width=15)
l = vLine(p)
l * p * l
```

## Horizontal line
Similar to `vLine` (surprising I know), but horizontal:
```@example layout
import Term.Layout: hLine

h1 = hLine(10; style="red")
h2 = hLine(10; style="blue")
h3 = hLine(p; style="green", box=:DOUBLE)
h1 / h2 / h3 / p
```

But! You can use some text to add a "title" to the center of your line:
```@example layout

hLine(100, "{bold white}wow{/bold white}")
```

which can be nice some times. 


## PlaceHolder
Does what it says on the tin. It's a convenience thing to create a renderable with a given size that you can use while you think about how to create a layout:

```@example layout
import Term.Layout: PlaceHolder

p1 = PlaceHolder(10, 35)
p2 = PlaceHolder(10, 35; style="red")
p3 = PlaceHolder(10, 75; style="blue")

(p1 * " "^5 * p2) / " " / p3
```


For more complex layout situations, `Grid` and `Compositor` are your friends. These are a bit more involved so we'll describe them more in detail in a dedicated `Layout` section below. 