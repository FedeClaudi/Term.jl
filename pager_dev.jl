using Term
using Term.LiveDisplays
using Term.Consoles
using Term.TermMarkdown

install_term_repr()
install_term_logger()
install_term_stacktrace()

using Markdown

text = parse_md(
    md"""
# Markdown rendering in Term.jl
## two
### three
#### four
##### five
###### six

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
    print("Hellow World")
end
```

---

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


""",
)

clear()

p = Pager(text; page_lines = 30, title = "Example pager")
p.internals
p |> LiveDisplays.play

stop!(p)
println("done")
