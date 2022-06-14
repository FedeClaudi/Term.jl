import OrderedCollections: OrderedDict
import Highlights: Lexers

using Highlights: Highlights
using Highlights.Format

# ------------------------------- highlighting ------------------------------- #
highlight_regexes = OrderedDict(
    :number => (r"(?<group>(?<![a-zA-Z0-9_#])\d+(\.\d*)?+([eE][+-]?\d*)?)",),
    :operator =>
        (r"(?<group>(?<!\{)\/)", r"(?<group>(?![\:\<])[\+\-\*\%\^\&\|\!\=\>\<\~])"),
    :string => (r"(?<group>[\"\']{3}|[\'\"]{1}(\n|.)*?[\"\']{3}|[\'\"]{1})",),
    :code => (r"(?<group>([\`]{3}|[\`]{1})(\n|.)*?([\`]{3}|[\`]{1}))",),
    :expression => (r"(?<group>\:\(+.+[\)])",),
    :symbol => (r"(?<group>(?<!\:)(?<!\:)\:\w+)",),
    :emphasis_light => (r"(?<group>[\[\]\(\)])", r"(?<group>@\w+)"),
    :type => (r"(?<group>\:\:[\w\.]*)", r"(?<group>\<\:\w+)"),
)

"""
    highlight(text::AbstractString, theme::Theme)

Highlighs a text introducing markup to style semantically
relevant segments, colors specified by a theme object
"""
function highlight(text::AbstractString; theme::Theme = TERM_THEME[])
    has_ansi(text) && return text

    # highlight with regexes 
    for (symb, rxs) in pairs(highlight_regexes)
        markup = getfield(theme, symb)
        open, close = "{$markup}", "{/$markup}"
        for rx in rxs
            text = replace(text, rx => SubstitutionString(open * s"\g<0>" * close))
        end
    end

    return remove_markup(apply_style(text))
end

"""
    highlight(text::AbstractString, theme::Theme, like::Symbol)

Hilights an entire text as if it was a type of semantically
relevant text of type :like.
"""
function highlight(text::AbstractString, like::Symbol; theme::Theme = TERM_THEME[])
    markup = getfield(theme, like)
    return apply_style(
        do_by_line((x) -> "{" * markup * "}" * x * "{/" * markup * "}", chomp(text)),
    )
end

# shorthand to highlight objects based on type
highlight(x::Union{UnionAll,DataType}; theme::Theme = TERM_THEME[]) =
    highlight(string(x), :type; theme = theme)

highlight(x::Number; theme::Theme = TERM_THEME[]) =
    highlight(string(x), :number; theme = theme)

highlight(x::Function; theme::Theme = TERM_THEME[]) =
    highlight(string(x), :func; theme = theme)

highlight(x::Symbol; theme::Theme = TERM_THEME[]) =
    highlight(string(x), :symbol; theme = theme)

highlight(x::Expr; theme::Theme = TERM_THEME[]) =
    highlight(string(x), :expression; theme = theme)

highlight(x::AbstractVector; theme::Theme = TERM_THEME[]) =
    highlight(string(x), :number; theme = theme)

highlight(x; theme = TERM_THEME[]) = string(x)  # capture all other cases

# ------------------------------ Highlighters.jl ----------------------------- #

"""
    Format.render(io::IO, ::MIME"text/ansi", tokens::Format.TokenIterator)

custom ANSI lexer for Highlighters.jl
"""
function Format.render(io::IO, ::MIME"text/ansi", tokens::Format.TokenIterator)
    for (str, id, style) in tokens
        fg = style.fg.active ? map(Int, (style.fg.r, style.fg.g, style.fg.b)) : ""
        bg = style.bg.active ? map(Int, (style.bg.r, style.bg.g, style.bg.b)) : nothing

        bold = style.bold ? "bold" : ""
        italic = style.italic ? "italic" : ""
        underline = style.underline ? "underline" : ""
        bg = isnothing(bg) ? "" : "on_$(bg)"
        markup = "$fg $(bg) $(bold) $(italic) $(underline)"
        if length(strip(markup)) > 0
            print(io, "{$markup}$str{/$markup}")
        else
            print(io, str)
        end
    end
end

"""
    highlight_syntax(code::AbstractString; style::Bool=true) 

Highlight Julia code syntax in a string.
"""
function highlight_syntax(code::AbstractString; style::Bool = true)
    txt = sprint(
        Highlights.highlight,
        MIME("text/ansi"),
        escape_brackets(code),
        Lexers.JuliaLexer,
        CodeTheme;
        context = stdout,
    )
    txt = unescape_brackets(txt)
    style && (txt = apply_style(txt))

    return do_by_line(rstrip, remove_markup(txt))
end

"""
    load_code_and_highlight(path::AbstractString, lineno::Int; δ::Int=3, width::INt=120)

Load a file, get the code and format it. Return styled text
"""
function load_code_and_highlight(path::AbstractString, lineno::Int; δ::Int = 3)
    η = countlines(path)
    @assert lineno > 0 "lineno must be ≥1"
    @assert lineno ≤ η "lineno $lineno too high for file with $(η) lines"

    lines = read_file_lines(path, lineno - 9, lineno + 10)

    linenos = first.(lines)
    lines = [ln[2] for ln in lines]
    code = split(highlight_syntax(join(lines); style = false), "\n")

    # clean
    clean(line) = replace(line, "    {/    }" => "")
    codelines = clean.(code)  # [10-δ:10+δ]
    linenos = linenos  # [10-δ:10+δ]

    # make n lines match
    if lineno ≤ δ
        codelines = clean.(code)[1:(lineno + δ)]
        linenos = linenos[1:(lineno + δ)]
    elseif η - lineno ≤ δ
        codelines = clean.(code)[(end - δ):end]
        linenos = linenos[(end - δ):end]
    else
        codelines = clean.(code)[(10 - δ):(10 + δ)]
        linenos = linenos[(10 - δ):(10 + δ)]
    end

    # format
    _len = textlen ∘ lstrip
    dedent = 100
    for ln in codelines
        if _len(ln) > 1
            dedent = min(dedent, textlen(ln) - _len(ln))
        end
    end
    dedent = dedent < 1 ? 1 : dedent

    cleaned_lines = []
    for (n, line) in zip(linenos, codelines)
        # style
        symb, color = if n == lineno
            "{red bold}❯{/red bold}", "white"
        else
            " ", "grey39"
        end

        # end
        line = textlen(line) > 1 ? lpad(line[dedent:end], 8) : line
        push!(cleaned_lines, symb * " {$color}$n{/$color} " * line)
    end

    return join(cleaned_lines, "\n")
end
