using Term.TermMarkdown
using Markdown
import Term: remove_ansi, escape_brackets

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

@testset "Test Markdown literal braces" begin
    # a brace in prose or in a code span prints as itself, once
    printed(md) = remove_ansi(chomp(sprint(tprint, Markdown.parse(md); context = stdout)))

    leaves = (
        "plain Tuple{Int} here",
        "*ital Tuple{Int}*",
        "**bold Tuple{Int}**",
        "# head Tuple{Int}",
        "- item Tuple{Int}",
        "> quote Tuple{Int}",
        "[link Tuple{Int}](http://x)",
        "`code Tuple{Int}`",
        "```julia\nf(x::Tuple{Int}) = x\n```",
    )
    for md in leaves
        out = printed(md)
        @test occursin("Tuple{Int}", out)
        @test !occursin("Tuple{{Int}}", out)
    end

    # a url is interpolated rather than recursed into
    @test occursin("http://x/{a}", printed("[label](http://x/{a})"))

    # nested parameters survive whole
    @test occursin("Vector{Vector{Int}}", printed("a Vector{Vector{Int}} here"))

    # the box is laid out around the printed width, wrapped or not
    long = "a Tuple{Int} and `Tuple{Int}` and Vector{Int} and Dict{Int} here, " *
        "plus enough further words to force the paragraph over several lines"
    for md in ("a Tuple{Int} and `Tuple{Int}` here", long)
        panel = Panel(RenderableText(Markdown.parse(md)); width = 44)
        lines = split(chomp(sprint(print, panel)), '\n')
        @test length(unique(map(l -> Term.textwidth(remove_ansi(l)), lines))) == 1
    end

    # stripping colour collapses the escape; doing both eats the braces
    Term.NOCOLOR[] = true
    try
        @test occursin("Tuple{Int}", printed("a Tuple{Int} here"))
        @test occursin(
            "Tuple{Int}",
            sprint(print, Panel(escape_brackets("a Tuple{Int} here"); width = 40)),
        )
    finally
        Term.NOCOLOR[] = false
    end
end
