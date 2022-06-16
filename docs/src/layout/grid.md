# Grid
Layout renderables (`hLine`, `vLine`), nesting, stacking... all very nice. But boy is it a lot of work sometimes to combine it all into a single layout!

Well that's were `grid` comes in (and `Compositor` too, see the next page).
The idea is simple: take a bunch of renderables and make a grid out of them:

```@example grid
import Term: Panel
import Term.Layout: grid

p = Panel(height=6, width=12)
panels = repeat([p], 8)

grid(panels)
```

Simple, but effective. `grid` gives you a lot of options to control the layout:
```@example grid
grid(panels; pad=2)  # specify padding
```

```@example grid
grid(panels; pad=(8, 1))  # hpad & vpad
```

You can also specify the apsect ratio of the grid:
```@example grid
grid(panels; aspect=1)
```

Note that with an aspect ratio of `1` the best way is to create `3` columns and `3` rows, but we only have `8` renderables! No problem, `grid` introduces a placeholder for the missing renderables. This is not shown by default, but you can see it with:
But you can hide it too:
```@example grid
grid(panels; aspect=1, show_placeholder=true)
```

One can use complex expressions for layouts, and use and underscore `_` to specify empty elements in the layout:
```@example grid
grid(panels[1:6]; layout=:((a * _ * b) / (_ * _ * c * d) / (_ * e * f)))
```

Finally you can use `layout` to more directly specify the number of rows and columns in the grid:
```@example grid
grid(panels; layout=(3, 4), show_placeholder=true)
```

!!! note 
    Note that grid uses `vstack` and `hstack` to combine the renderables into the layout you requested. As such, it returns a single renderable, you don't have access to the individual renderables that went into making the grid any longer. This also means that the grid can be stack with other content to create a larger layout. 


