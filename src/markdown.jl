module TermMarkdown

using Markdown
import OrderedCollections: OrderedDict

import UnicodeFun: to_latex

import Term:
    reshape_text,
    highlight_syntax,
    escape_brackets,
    default_width,
    TERM_THEME,
    reshape_code_string
import ..Tables: Table
import ..Style: apply_style
import ..Layout: pad, hLine, vLine
import ..Consoles: console_width
import ..Renderables: RenderableText
import ..Renderables
import ..Tprint: tprint, tprintln
import ..Tprint
import ..Panels: Panel
import ..Segments: Segment

export parse_md

# ---------------------------------------------------------------------------- #
#                                   PARSE MD                                   #
# ---------------------------------------------------------------------------- #

"""
    parse_md

Parse a Markdown element (Paragraph, List...) into a string.

A `width` keyword argument can be used to control the width of 
the string representation and an `inline` boolean argument specifies
when an element (e.g. a code snippet) is in-line within a larger element
(e.g. a paragraph).
"""
function parse_md end

parse_md(text::String) = parse_md(Markdown.parse(text))
parse_md(x; kwargs...)::String = string(x)

"""
    parse_md(text::Markdown.MD; kwargs...)::String

Parse an entier `MD` object by parsing its constituent elements
and joining the resulting strings.
"""
function parse_md(text::Markdown.MD; width = default_width(), kwargs...)::String
    elements = parse_md.(text.content; width = width, kwargs...)
    return join(elements, "\n\n")
end

"""
    parse_md(header::Markdown.Header{l}; width = console_width(), kwargs...) where {l}

Parse `Headers` with different style based on the level
"""
function parse_md(header::Markdown.Header{l}; width = default_width(), kwargs...) where {l}
    theme = TERM_THEME[]
    header_styles = Dict(
        1 => theme.md_h1,
        2 => theme.md_h2,
        3 => theme.md_h3,
        4 => theme.md_h4,
        5 => theme.md_h5,
        6 => theme.md_h6,
    )

    header_justify =
        Dict(1 => :center, 2 => :center, 3 => :center, 4 => :left, 5 => :left, 6 => :left)

    style = header_styles[l]
    header_text = chomp(join(map(ln -> "{$style}$ln{/$style}\n", header.text))) |> rstrip
    if l > 1
        header_text = reshape_text(header_text, width)
        return pad(header_text, width - 1, header_justify[l])
    else
        return string(
            Panel(
                header_text;
                box = :HEAVY,
                style = "dim",
                width = width - 8,
                justify = :center,
                padding = (2, 2, 0, 0),
                fit = false,
            ),
        )
    end
end

"""
    parse_md(paragraph::Markdown.Paragraph; width = console_width(), kwargs...)::String

Parse each element in a paragraph
"""
function parse_md(paragraph::Markdown.Paragraph; width = console_width(), kwargs...)::String
    out = join(parse_md.(paragraph.content; inline = true, width = width))
    return reshape_text(out, width) * "\e[0m"
end

parse_md(italic::Markdown.Italic; kwargs...)::String =
    join(map(ln -> "{italic}$(ln){/italic}", italic.text))

parse_md(bold::Markdown.Bold; kwargs...)::String =
    join(map(ln -> "{bold}$(ln){/bold}", bold.text))

parse_md(lb::Markdown.LineBreak; kwargs...)::String = "\n"

"""
---
    function parse_md(
        ltx::Markdown.LaTeX;
        inline = false,
        width = console_width(),
        kwargs...,
    )::String

Parse a math element.
Try to convert it to unicode characters when possible,
otherwise output the latex string.
"""
function parse_md(
    ltx::Markdown.LaTeX;
    inline = false,
    width = console_width(),
    kwargs...,
)::String
    formula = ""
    try
        formula = escape_brackets(to_latex(escape_string(string(ltx.formula))))
    catch
        formula = string(ltx.formula)
    end

    theme = TERM_THEME[]
    if inline
        return "{$(theme.md_latex)}" * formula * "{/$(theme.md_latex)}"
    else
        txt = "\n     {$(theme.md_latex)}" * formula * "{/$(theme.md_latex)}\n"
        return reshape_text(txt, width) * "\e[0m"
    end
end

"""
---
    function parse_md(
        code::Markdown.Code;
        width = console_width(),
        inline = false,
        kwargs...,
    )::String

Parse a code snippet with syntax highlighting (for Julia code).

For non-inline code snippets the code is put in a panel
with different background coloring to make it stand out.
"""
function parse_md(
    code::Markdown.Code;
    width = console_width(),
    inline = false,
    lpad = true,
    kwargs...,
)::String
    syntax = reshape_code_string(highlight_syntax(code.code), width - 20)
    theme = TERM_THEME[]
    if inline
        return "{$(theme.md_code)}`$(code.language){/$(theme.md_code)}" *
               syntax *
               "{$(theme.md_code)}`{/$(theme.md_code)}"
    else
        panel = Panel(
            RenderableText(syntax; style = "on_$(theme.md_codeblock_bg)");
            style = "white on_$(theme.md_codeblock_bg)",
            box = :SQUARE,
            subtitle = length(code.language) > 0 ? code.language : nothing,
            width = width - 12,
            background = "on_$(theme.md_codeblock_bg)",
            subtitle_justify = :right,
            fit = false,
        )

        return if lpad
            string("    " * panel)
        else
            string(panel)
        end
    end
end

"""
    function parse_md(
        qt::Markdown.BlockQuote;
        width = default_width(),
        kwargs...,
    )::String

Style a BlockQuote with a line and a quotation marker.
"""
function parse_md(qt::Markdown.BlockQuote; width = default_width() - 1, kwargs...)::String
    content = parse_md.(qt.content; inline = true)
    content = length(content) > 1 ? join(content) : content[1]
    # content = reshape_text(content, width-1)
    theme = TERM_THEME[]
    content =
        "{$(theme.text_accent)}“{/$(theme.text_accent)}" *
        content *
        "{$(theme.text_accent)}”{/$(theme.text_accent)}\e[0m"

    content = RenderableText(content; width = width - 5)
    line =
        content.measure.h > 1 ?
        (
            "{$(theme.md_quote)}>{/$(theme.md_quote)}" /
            vLine(content.measure.h - 1; style = "$(theme.md_quote) dim", box = :HEAVY)
        ) : "{$(theme.md_quote)}>{/$(theme.md_quote)}"
    string("  " * line * " " * content)
end

parse_md(hl::Markdown.HorizontalRule; width = default_width(), kwargs...)::String =
    string(hLine(width - 1; style = "dim", box = :HEAVY))

"""
    function parse_md(
        list::Markdown.List;
        width = console_width(),
        inline = false,
        space = "",
    )::String

Parse a list and all its elements, for both numbered and unnumbered lists.
"""
function parse_md(
    list::Markdown.List;
    width = console_width(),
    inline = false,
    space = "",
)::String
    theme = TERM_THEME[]
    list_elements = []
    for item in list.items
        push!(list_elements, join(parse_md.(item)))
    end

    rendered = ""
    for (i, item) in enumerate(list.items)
        bullet = if Markdown.isordered(list)
            "$space{bold}" * "  $(i + list.ordered - 1). " * "{/bold}"
        else
            "$space{$(theme.text_accent)}" * "  • " * "{/$(theme.text_accent)}"
        end

        item_content = map(
            elem ->
                elem isa Markdown.List ? "\n" * parse_md(elem; space = "   ") :
                parse_md(elem; inline = true),
            item,
        )
        item_content = length(item_content) > 1 ? join(item_content) : item_content[1]
        rendered *= bullet * item_content * "\n"
    end
    return reshape_text(rendered, width)
end

function parse_md(img::Markdown.Image; kwargs...)::String
    "{dim} 🌄 image: {/dim}" * img.alt * " {dim}| at: " * img.url * "{/dim}"
end

"""
    parse_md(note::Markdown.Footnote; width = console_width(), inline = false)

Style a footnote differently based on if they are a renference to it or its content.
"""
function parse_md(note::Markdown.Footnote; width = console_width(), inline = false)
    theme = TERM_THEME[]
    if isnothing(note.text)
        return id = "{$(theme.md_footnote)}[$(note.id)]{/$(theme.md_footnote)}"
    else
        id =
            (inline ? "\n" : "") *
            "{$(theme.md_footnote)}[$(note.id)]{/$(theme.md_footnote)}"
        content = parse_md.(note.text)
        return if length(content) == 1
            string(RenderableText("$id: " * content[1]; width = width))
        else
            string(RenderableText("$id:\n" * join(content); width = width))
        end
    end
end

function parse_md(content::Vector; kwargs...)::String
    content = parse_md.(content; kwargs...)
    return if length(content) == 1
        content[1]
    else
        join(content)
    end
end

"""
    function parse_md(tb::Markdown.Table; width = console_width())::String

Convert a markdown Table to a `Table` renderable.
"""
function parse_md(tb::Markdown.Table; width = console_width())::String
    just = Dict(:l => :left, :r => :right, :c => :center)
    header = parse_md.(tb.rows[1])
    table_content = OrderedDict(
        header[i] => [parse_md(r[i]; inline = true) for r in tb.rows[2:end]] for
        i in 1:length(header)
    )

    return string(
        pad(
            Table(
                table_content;
                columns_justify = [just[j] for j in tb.align],
                box = :ROUNDED,
                header_style = TERM_THEME[].md_table_header,
                style = "dim",
            );
            width = width - 8,
        ),
    )
end

parse_md(link::Markdown.Link; kwargs...)::String =
    "{white bold}$(parse_md(link.text; inline=true)){/white bold} {dim}($(link.url)){/dim}"

"""
    function parse_md(ad::Markdown.Admonition; width = console_width(), kwargs...)::String

Parse adomitions and style them with colored `Panel` renderables.
"""
function parse_md(ad::Markdown.Admonition; width = console_width(), kwargs...)::String
    theme = TERM_THEME[]
    title_styles = Dict(
        "note" => theme.md_admonition_note,
        "info" => theme.md_admonition_info,
        "warning" => theme.md_admonition_warning,
        "danger" => theme.md_admonition_danger,
        "tip" => theme.md_admonition_tip,
    )
    has_title = length(ad.title) > 0
    content = parse_md(ad.content; inline = true)
    content = reshape_text(content, width - 10)
    style = get(title_styles, ad.category, theme.text)
    return string(
        "    " * Panel(
            content;
            title = has_title ? parse_md(ad.title) : "",
            title_style = has_title ? style * " default" : "",
            style = style * " dim",
            width = width - 8,
            fit = false,
        ),
    )
end

# ---------------------------------------------------------------------------- #
#                              RENDERABLE & TPRINT                             #
# ---------------------------------------------------------------------------- #

"""
---
    RenderableText(md::Markdown.MD; width = console_width() - 2, kwargs...)

Create a `RenderableText` from a markdown string.
"""
Renderables.RenderableText(md::Markdown.MD; width = console_width() - 2, kwargs...) =
    RenderableText(parse_md(md; width = width); width = width, kwargs...)

"""
---
    tprint(md::Markdown.MD; kwargs...)

Print a parsed markdown string.
"""
Tprint.tprint(md::Markdown.MD; kwargs...) = tprint(parse_md(md); kwargs...)
Tprint.tprint(io::IO, md::Markdown.MD; kwargs...) = tprint(io, parse_md(md); kwargs...)

"""
---
    tprintln(md::Markdown.MD; kwargs...)

Print a parsed markdown string.
"""
Tprint.tprintln(md::Markdown.MD; kwargs...) = tprintln(parse_md(md); kwargs...)
Tprint.tprintln(io::IO, md::Markdown.MD; kwargs...) = tprintln(io, parse_md(md); kwargs...)
end
