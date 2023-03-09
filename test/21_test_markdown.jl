using Term.TermMarkdown
using Markdown

m1 = md"""
This is a test function for math syntax

```math
\\alpha^2 - \\sqrt9 \\in [1, 2, 3] \\cup [4, 5, 6]
```
"""

m2 = md"""
# Markdown rendering in Term.jl
## twp
### three
#### four
##### five
###### six
"""

m3 = md"""
This is an example of markdown content rendered in Term.jl.
You can use markdown syntax to make words **bold** and *italic* or insert `literals`.


You markdown can include in-line latex ``\LaTeX  \frac{{1}}{{2}}`` and maths in a new line too:

```math
f(a) = \frac{1}{2\pi}\int_{0}^{2\pi} (\alpha+R\cos(\theta))d\theta
```

You can also have links: [Julia](http://www.julialang.org) and
footnotes [^1] for your content [^named].

And, of course, you can show some code too:

```julia
function say_hi(x)
    print("Hello World")
end
```

---

You can use "quotes" to highlight a section:

> Multi-line quotes can be helpful to make a 
> paragraph stand out, so that users won't miss it!
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

---

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


!!! note "Tables"
    You can use the [Markdown table syntax](https://www.markdownguide.org/extended-syntax/#tables)
    to insert tables - Term.jl will convert them to Table object!

| Term | handles | tables|
|:---------- | ---------- |:------------:|
| Row `1`    | Column `2` |              |
| *Row* 2    | **Row** 2  | Column ``3`` |


----

This is where you print the content of your foot notes:

[^1]: Numbered footnote text.

[^note]:
    Named footnote text containing several toplevel elements.

"""

@testset "Test Markdown Strings" begin
    for (i, m) in enumerate([m1, m2, m3])
        t = parse_md(m; width = 60)
        IS_WIN || @compare_to_string(t, "markdown_$i")
    end
end
