# Markdown
If you've had a loot at the `REPR` section, you might have noticed that Term is doing some fancy print out of the functions docstrings. That's because docstrings in Julia are represented as Markdown text and Term can parse it nicely!

Let's have a look.

```@example md
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

```math
f(a) = \alpha \cdot \theta
```
""")

```

### Code

```@example md
tprint(md"""

```julia
function say_hi(x)
    print("Hellow World")
end
```
""")
```

### Quotes and admonitions
```@example md
tprint(md"""
You can use "quotes" to highlight a section:

> Multi-line quotes can be helpful to make a 
> paragram stand out, so that users won't miss it!
> You can use **other inline syntax** in you `quotes` too.
 
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
```


and more (links, footnoes, headers of different levels, etc.)