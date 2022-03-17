# Layout renderables
We've already [seen the layout elements](@ref content_layout) in detail, but we'll just remind you of them here.
There's three types of renderabels whick mainly aime with getting the right layout for your renderables: `Spacer`, `vLine` and `hLine`.  

`Spacer` creates a *box* of empty text with a given width and height. This can be useful for instance if you're stacking two other renderables but want some space between them:
```@example
import Term: Panel, Spacer


p = Panel(; width=10, height=3)
space = Spacer(5, 3)
print(p * space * p)
print(p * p)
```

`vLine` and `hLine` are more useful to create a separation between two separate peices of content:
```@example

import Term: TextBox, vLine, hLine


my_long_text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut..."

tb = TextBox(my_long_text; width=22)
line = " " /vLine(tb.measure.h-2; style="dim bold")

top = tb * line * tb

tb2 = TextBox(my_long_text; width=top.measure.w)
hline = hLine(top.measure.w; style="dim", box=:DOUBLE)

print(top / hline / tb2)
```