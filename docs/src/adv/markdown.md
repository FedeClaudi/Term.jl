# Markdown
If you've had a loot at the `REPR` section, you might have noticed that Term is doing some fancy print out of the functions docstrings. That's because docstrings in Julia are represented as Markdown text and Term can parse it nicely!

Let's have a look.

```@example md
import Term.Consoles: Console, enable, disable # hide
con = Console(60) # hide
enable(con) #hide
import Term: tprintln
using Term.TermMarkdown
using Markdown

mymd = md"""
# This is a Markdown file

This is a paragraph of text.
This is a list:
* one
* two
"""
```

and now in Term:
```@example md
import Term: tprintln, tprint
tprintln(parse_md(mymd))
```

or more simply:
```@example md
tprint(mymd)
```

Anything that goes into a Julia's Markdown object can be rendered nicely.

### Maths
```@example md
tprint(md"""
You markdown can include in-line latex ``\sqrt(\gamma)`` and maths in a new line too:


!!! warning
    this is where you'd put multi-line math, but it doesn't work in Documenter - sorry.
    Have a go in your own REPL!
""")

```

### Code

This is what you'd do to show code:
```julia

tprint("""

"this function is a bit pointless"
function my_useless_fn(x)
    println("I don't do much!")
    return x
end

""")
```


```@example md
tprint(md"""

!!! warning
    this is where you'd put multi-line code, but it doesn't work in Documenter - sorry.
    Have a go in your own REPL!
""")
```

### Quotes and admonitions
```@example md
tprint(md"""
You can use "quotes" to highlight a section:

> Multi-line quotes can be helpful to make a 
> paragraph stand out, so that users won't miss it!

but if you really need to grab someone's attention, use admonitions:

!!! note
    You can use different levels

!!! warning
    to send different messages

!!! danger
    to your reader

!!! tip "Wow!"
    Turns out that admonitions can be pretty useful!
    What will you use them for?
""")
```

### Lists
```@example md
tprint(md"""
Of course you can have classic lists:
* item one
* item two
* And a sublist:
    + sub-item one
    + sub-item two

and ordered lists too:
1. item one
2. item two
3. item three

""")
```

### Tables
```@example md
tprint(md"""
!!! note "Tables"
    You can use the [Markdown table syntax](https://www.markdownguide.org/extended-syntax/#tables)
    to insert tables - Term.jl will convert them to Table object!

| Term | handles | tables|
|:---------- | ---------- |:------------:|
| Row `1`    | Column `2` |              |
| *Row* 2    | **Row** 2  | Column ``3`` |
""")

disable(con)  # hide
```


and more (links, footnotes, headers of different levels, etc.)