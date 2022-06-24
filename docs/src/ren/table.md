# Table
You know what a table is. You probably also know that Julia has an awesome `Tables` interface for handling tabular data (e.g. that's what `DataFrames` uses). All that `Term` does here is that that and make it look fancy. 

```@example tb
using Term.Tables
t = 1:3
data = hcat(t, rand(Int8, length(t)))
Table(data) # or use a matrix!
```

nothing spectacular so far, but `Table` has a ton of options.

### Box style
You can adjust the box used and its style
```@example tb
Table(data; box=:ROUNDED, style="red")
```
```@example tb
Table(data; box=:SIMPLE, style="dim bold")
```
```@example tb
Table(data; box=:MINIMAL_DOUBLE_HEAD, style="dim bold green")
```

### Header
You can set the header style:
```@example tb
Table(data; header_style="bold green")
```
and setting each style independently
```@example tb
Table(data; header_style=["bold green", "dim"])
```


you can also set what the header should be and if it should be left-center-right justified:
```@example tb
Table(data; header=["A", "B"], header_justify=[:left, :right])
```

!!! note
    For all parameters that apply to the header, columns and footer; you can either pass a single parameter or a vector of parameters. If a single parameter is passed, it will be applied to all the columns, otherwise each element of the vector is applied to each column.

### Footer
Very similar to the header, but at the bottom:
```@example tb
Table(data; footer=["A", "B"], footer_justify=[:left, :right], footer_style="bold green")
```

a nice little thing: use functions to create a footer:
Table(data; footer=sum)

### Columns
Like for header and footer you can set the style and justification of the columns, all together or independently:
```@example tb
Table(data; columns_style=["bold green", "dim"], columns_justify=[:left, :right])
```

but there's more (there always is, isn't it?):
```@example tb
import Term.Layout: PlaceHolder
ph1 = PlaceHolder(3, 12)
ph2 = PlaceHolder(5, 12)
ph3 = PlaceHolder(7, 12)

data = Dict(
    "first\ncol." => [ph1, ph2, ph3],
    "second\ncol." => [ph1, ph2, ph3],
    "third\ncol." => [ph3, ph1, ph3],
)

Table(data)
```

and now look, vertical justify!
```@example tb
Table(data; vertical_justify= :bottom)
```

### Padding
Finally, you can use `hpad` and `vpad` to adjust the padding of the table:
```@example tb
t = 1:3
data = hcat(t, rand(Int8, length(t)))
Table(data; hpad=20) 
```
and
```@example tb
Table(data; vpad=5)
```

as you can see it changes the size of the cells around the content.


That's all you need to know about how to make a `Table`. You can play around with the parameters to make great looking tables!
```@example tb
data = Dict(
    :Parameter => [:α, :β, :γ],
    :Value => [1, 2, 3],
)

Table(data;
    header_style="bold white on_black",
    header_justify=[:right, :left],
    columns_style=["bold white", "dim"],
    columns_justify=[:right, :left],
    footer=["", "{bold red}3{/bold red} params"],
    footer_justify=[:right, :left],
    box=:SIMPLE,
    style="#9bb3e0"
)
```