# tprint 
We've seen tprint before. When passed a string with markup information it will print it with the correct style.

```@example tp
import Term: tprint
tprint("This text has {bold gold1 underline}style!")
```

But there's more. Compare `Base.print` with `Term.tprint` here:
```@example tp
print("This is a: ", 1, "of type", typeof(1), "this is a function", print)
print("\n") # hide
tprint("This is a: ", 1, "of type", typeof(1), "this is a function", print)
```

you can see two differences. The first is that when passing multiple comma separated arguments `tprint` inserts a space between them, making the output easier to parse. The second is that it colors certain objects types (`Number`, `DataType` and `Function` in the example). Thus any number will be printed blue, function names will be yellow etc.

In addition, `tprint` will automatically highlight numbers, types etc... in your strings.
```@example tp
tprint("This is a: 1 of type ::Int64 this is a function `print`")
```

!!! info "highlighting"
    By default `tprint` highlights strings before printing them out. If you don't like that, set `tprint(...; highlight=false)`! Also, if your text already has markup or ANSI style information, it won't be highlighted: highlighting styled text get messy!

`Tprint` can also print renderables, of course.
```@example
using Term # hide
tprint(Panel(; width=22, height=2), Panel(; width=22, height=3))
```
As you can see the renderables are printed one above the other. 


Finally, you should know that like `print` has `println`, so `tprint` has `tprintln` to add a new line to the output.

With this we conclude our overview of the basic elements of `Term`: markup style to create styled text, `tprint` to print it to console, renderables like `Panel` and `TextBox` and the layout syntax to create beautiful terminal output. 
There's a lot more you can use `Term` for, but styled text, panels and layout operators will get you far! Enjoy!


