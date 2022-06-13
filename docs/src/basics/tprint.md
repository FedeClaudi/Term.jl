# tprint 
We've seen tprint before. When passed a string with markup information it will print it with the correct style.

```@example
using Term # hide
tprint("This text has {bold gold1 underline}style!")
```

But there's more. Compare `Base.print` with `Term.tprint` here:
```@example
using Term # hide
print("This is a: ", 1, "of type", typeof(1), "this is a function", print)
print("\n") # hide
tprint("This is a: ", 1, "of type", typeof(1), "this is a function", print)
```

you can see two differences. The first is that when passing multiple comma separated arguments `tprint` inserts a space between them, making the output easier to parse. The second is that it colors certain objects types (`Number`, `DataType` and `Function` in the example). Thus any number will be printed blue, function names will be yellow etc.

Note that `tprint` can only highlight objects based on their type (e.g., `1` above is of type `Int64`, not a string `"1"`.). So this won't work:
```example
using Term # hide
tprint("This is a: 1 of type Int64 this is a function print")
```
But, we are working on a `highlight` feature that will be able to parse strings and color their elements correctly. Like this:
```@example
import Term: tprint, highlight
tprint(highlight("This is a: 1 of type ::Int64 this is a function print"))
```


`Tprint` can also print renderables, of course.
```@example
using Term # hide
tprint(Panel(; width=22, height=2), Panel(; width=22, height=3))
```
As you can see the renderables are printed one above the other. 


Finally, you should know that like `print` has `println`, so `tprint` has `tprintln` to add a new line to the output.

With this we conclude our overview of the basic elements of `Term`: markup style to create styled text, `tprint` to print it to console, renderables like `Panel` and `TextBox` and the layout syntax to create beautiful terminal output. 
There's a lot more you can use `Term` for, but styled text, panels and layout operators will get you far! Enjoy!
