using Term
import Term: highlight_syntax

install_term_logger()
install_term_repr()

using Markdown

a = md"""
# header

Content hehe

This has *inline test* `print(x)`


```
print(:x)
√9 - :x
```

- x
- y


"""

termshow(a.content)

function parse_md(header::Markdown.Header)
    style = "bold red"
    join(map(ln -> "{$style}$ln{/$style}\n", a.content[1].text))
end

function parse_md(paragraph::Markdown.Paragraph)
    join(parse_md.(paragraph.content))
end

parse_md(italic::Markdown.Italic) = join(map(ln -> "{italic}$(ln){/italic}", italic.text))

parse_md(code::Markdown.Code) = highlight_syntax(code.code)

function parse_md(list::Markdown.List)
    list_elements = map(item -> join(parse_md.(item)), list.items)
    if list.ordered > 0
        return join(map((i, l) -> " {bold}$i{/bold} " * l, enumerate(list_elements)), "\n")
    else
        return join(map((l) -> " {bold}•{/bold} " * l, list_elements), "\n")
    end
end

parse_md(x) = string(x)

function parse_md(text::Markdown.MD)
    elements = parse_md.(text.content)
    return join(elements, "\n")
end

tprint(parse_md(a))
