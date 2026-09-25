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


You markdown can include in-line latex ``\LaTeX  \frac{1}{2}`` and maths in a new line too:

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

@testset "Test Markdown empty list items" begin
    # an item with no content renders as an empty bullet
    unordered = cleantext(parse_md(Markdown.parse("- a\n-\n- b\n"); width = 60))
    @test count("•", unordered) == 3
    @test occursin("• a", unordered)
    @test occursin("• b", unordered)

    # the empty item keeps its place, so numbering does not shift
    ordered = cleantext(parse_md(Markdown.parse("1. a\n2.\n3. b\n"); width = 60))
    @test occursin("1. a", ordered)
    @test occursin("2. ", ordered)
    @test occursin("3. b", ordered)

    # a lone bullet, and an empty item nested in another list
    @test_nothrow parse_md(Markdown.parse("-\n"); width = 60)
    @test_nothrow parse_md(Markdown.parse("- a\n    + b\n    +\n"); width = 60)
end

@testset "Test Markdown nested tables" begin
    # the recursion passes `inline = true` down to whatever it finds nested
    rows = ["| a | b |", "|---|---|", "| 1 | 2 |"]
    tb = join(rows, '\n') * "\n"
    in_list = "- item\n\n" * join("  " .* rows, '\n') * "\n"
    in_quote = "> quote\n>\n" * join("> " .* rows, '\n') * "\n"

    @test_nothrow parse_md(Markdown.parse(tb); width = 60)        # top level
    @test_nothrow parse_md(Markdown.parse(in_list); width = 60)   # in a list item
    @test_nothrow parse_md(Markdown.parse(in_quote); width = 60)  # in a block quote

    for src in (in_list, in_quote)
        out = cleantext(parse_md(Markdown.parse(src); width = 60))
        @test occursin("a", out) && occursin("1", out)
    end

    # every method tolerates the keywords the recursion passes
    @test_nothrow parse_md(Markdown.parse("[^1]: a note\n"); width = 60, space = "  ")
end

@testset "Test Markdown nested tables" begin
    # the recursion passes `inline = true` down to whatever it finds nested
    rows = ["| a | b |", "|---|---|", "| 1 | 2 |"]
    tb = join(rows, '\n') * "\n"
    in_list = "- item\n\n" * join("  " .* rows, '\n') * "\n"
    in_quote = "> quote\n>\n" * join("> " .* rows, '\n') * "\n"

    @test_nothrow parse_md(Markdown.parse(tb); width = 60)        # top level
    @test_nothrow parse_md(Markdown.parse(in_list); width = 60)   # in a list item
    @test_nothrow parse_md(Markdown.parse(in_quote); width = 60)  # in a block quote

    for src in (in_list, in_quote)
        out = cleantext(parse_md(Markdown.parse(src); width = 60))
        @test occursin("a", out) && occursin("1", out)
    end

    # every method tolerates the keywords the recursion passes
    @test_nothrow parse_md(Markdown.parse("[^1]: a note\n"); width = 60, space = "  ")
end

@testset "Test Markdown table header cells are inline" begin
    # A header cell is inline content, exactly as a body cell is: a code span in
    # one comes out a span, so the header stays one line tall and the table
    # keeps the width it was asked for.
    tb = "| a | `f(::T)` | c |\n|---|---|---|\n| 1 | 2 | 3 |\n"
    lines = split(rstrip(cleantext(parse_md(Markdown.parse(tb); width = 60))), '\n')

    @test length(lines) == 5              # border, header, rule, row, border
    @test all(l -> length(l) <= 60, lines)
    @test occursin("f(::T)", lines[2])    # and the header kept its text
end

@testset "Test Markdown header inline elements" begin
    # A header's elements are inline content, one line of them: a code span or
    # a link in a header continues the line rather than starting a new one.
    for md in ("## head `z` tail", "# head `z` tail", "#### head [l](http://a) tail")
        lines = filter(!isempty, strip.(split(cleantext(parse_md(Markdown.parse(md); width = 60)), '\n')))
        text = only(filter(l -> occursin("head", l), lines))
        @test occursin("tail", text)
        @test !any(l -> occursin("Markdown.", l), lines)
    end

    # the same holds for emphasis, which recurses into what it contains
    out = cleantext(parse_md(Markdown.parse("**Why `JL_GC_PUSHARGS` frames** and *em `x` y*"); width = 80))
    @test !occursin("Markdown.", out)
    @test occursin("JL_GC_PUSHARGS", out)
end

@testset "Test Markdown table fits the width" begin
    long = "reverted `base/binaryplatforms.jl` and a `LibUnwind_jll` bump, both of which " *
        "auto-merged but are out of scope here; dropped the `LazyLibrary` hunk"
    src = "| PR | Changed afterward |\n|---|---|\n| #58731 | $long |\n| #60369 | nothing |\n"

    for width in (40, 60, 80, 100)
        lines = split(cleantext(parse_md(Markdown.parse(src); width = width)), '\n')
        @test all(l -> textwidth(l) ≤ width, lines)

        # every cell's text is there, in order, however it was wrapped
        cells = [strip.(split(l, '│')) for l in lines if count('│', l) == 3]
        expected = [("PR", "#58731", "#60369"), ("Changed afterward", long, "nothing")]
        for (col, texts) in zip((2, 3), expected)
            text = replace(join(getindex.(cells, col)), ' ' => "")
            @test all(t -> occursin(replace(t, ' ' => ""), text), texts)
        end
    end

    # a table that fits keeps its columns as wide as their widest cell
    @test isnothing(TermMarkdown.table_columns_widths([["a", "bb"], ["ccc", "d"]], 60))
    # and one that cannot fit even at its longest words is not squeezed further
    @test isnothing(TermMarkdown.table_columns_widths([["a"^15, "b"^15]], 30))

    # nested, a table starts a line of its own
    rows = ["| a | b |", "|---|---|", "| 1 | 2 |"]
    in_list = "- item\n\n" * join("  " .* rows, '\n') * "\n"
    lines = split(cleantext(parse_md(Markdown.parse(in_list); width = 60)), '\n')
    @test any(l -> occursin("item", l) && !occursin('╭', l), lines)
    @test any(l -> startswith(l, '╭'), lines)
end

@testset "Test Markdown table look from the theme" begin
    src = "| a | b |\n|---|---|\n| 1 | 2 |\n| 3 | 4 |\n| 5 | 6 |\n"
    render() = filter(!isempty, strip.(split(cleantext(parse_md(Markdown.parse(src); width = 40)), '\n')))

    # by default: a rounded frame, and a rule under the header and every row
    lines = render()
    @test startswith(first(lines), '╭')
    @test count(l -> occursin('─', l), lines) == 5

    # much as GitHub draws it: only the header rule, and no frame
    theme = Term.TERM_THEME[]
    try
        Term.TERM_THEME[] = Term.Theme(md_table_box = :MINIMAL_HEAVY_HEAD, md_table_compact = true)
        lines = render()
        @test !any(l -> occursin(r"[╭╰─]", l), lines)
        @test count(l -> occursin('━', l), lines) == 1
        @test count(l -> occursin('│', l), lines) == 4
    finally
        Term.TERM_THEME[] = theme
    end
end

@testset "Test Markdown code block look from the theme" begin
    src = "```julia\nf(x) = x + 1\n```\n"
    render() = split(cleantext(parse_md(Markdown.parse(src); width = 40)), '\n')

    # by default: a square panel, indented by four columns
    lines = render()
    @test startswith(first(lines), "    ┌")
    @test any(l -> occursin("f(x) = x + 1", l), lines)

    theme = Term.TERM_THEME[]
    try
        Term.TERM_THEME[] = Term.Theme(md_codeblock_box = :NONE, md_codeblock_indent = 0)
        lines = render()
        @test !any(l -> occursin(r"[┌┐└┘│─]", l), lines)
        @test any(l -> occursin("f(x) = x + 1", l), lines)
        @test all(l -> textwidth(l) == textwidth(first(lines)), lines)
        @test textwidth(first(lines)) == 28  # the panel alone, `width - 12`
    finally
        Term.TERM_THEME[] = theme
    end
end
