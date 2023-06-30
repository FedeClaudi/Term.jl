import OrderedCollections: OrderedDict
import Highlights: Lexers

using Highlights: Highlights
using Highlights.Format

# ------------------------------- highlighting ------------------------------- #
highlight_regexes = OrderedDict(
    :number => (r"(?<group>(?<![a-zA-Z0-9_#])\d+(\.\d*)?+([eE][+-]?\d*)?)",),
    :operator => (
        r"(?<group>(?<!\{)\/)",
        r"(?<group>(?![\:\<])[\+\-\*\%\^\&\|\!\=\>\<\~\[\]×])",
    ),
    :string => (r"(?<group>[\'\"][\w\n]*[\'\"])",),
    :code => (r"(?<group>([\`]{3}|[\`]{1})(\n|.)*?([\`]{3}|[\`]{1}))",),
    :expression => (r"(?<group>\:\(+.+[\)])",),
    :symbol => (r"(?<group>(?<!\:)(?<!\:)\:\w+)",),
    # :emphasis_light => (r"(?<group>[\[\]\(\)])", r"(?<group>@\w+)"),
    :type => (r"(?<group>\:\:[\w\.]*)", r"(?<group>\<\:\w+)"),
)

"""
    highlight(text::AbstractString, theme::Theme)

Highlighs a text introducing markup to style semantically
relevant segments, colors specified by a theme object.
"""
function highlight(
    text::AbstractString;
    theme::Theme = TERM_THEME[],
    ignore_ansi::Bool = false,
)
    (has_ansi(text) && !ignore_ansi) && return text

    # highlight with regexes 
    for (symb, rxs) in pairs(highlight_regexes)
        markup = getfield(theme, symb)
        open, close = "{$markup}", "{/$markup}"
        for rx in rxs
            text = replace(text, rx => SubstitutionString(open * s"\g<0>" * close))
        end
    end

    return text
end

"""
    highlight(text::AbstractString, theme::Theme, like::Symbol)

Hilights an entire text as if it was a type of semantically
relevant text of type :like.
"""
highlight(text::AbstractString, like::Symbol; theme::Theme = TERM_THEME[]) =
    apply_style(text, getfield(theme, like))

# shorthand to highlight objects based on type
highlight(x; theme = TERM_THEME[]) = apply_style(string(x), theme(x)) # capture all other cases

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
    style && (txt = apply_style(txt))
    return remove_markup(txt)
end

"""
    load_code_and_highlight(path::AbstractString, lineno::Int; δ::Int=3, width::INt=120)

Load a file, get the code and format it. Return styled text
"""
function load_code_and_highlight(path::AbstractString, lineno::Int; δ::Int = 3)::String
    η = countlines(path)
    @assert lineno > 0 "lineno must be ≥1"
    @assert lineno ≤ η "lineno $lineno too high for file with $(η) lines"

    lines = read_file_lines(path, lineno - δ, lineno + δ)
    linenos = first.(lines)
    code =
        [highlight_syntax((δ == 0 ? lstrip(ln[2]) : ln[2]); style = true) for ln in lines]
    code = split(join(code), "\n")

    # clean
    clean(line) = replace(line, "    {/    }" => "", '\r' => "")
    codelines = clean.(code)  # [10-δ:10+δ]
    linenos = linenos  # [10-δ:10+δ]

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

        line = textlen(line) > 1 ? lpad(line[dedent:end], 8) : line
        push!(cleaned_lines, symb * " {$color}$n{/$color} " * line)
    end

    return join(cleaned_lines, "\n")
end

"""
    load_code_and_highlight(path::AbstractString)::String

Load and highlight the syntax of an entire file
"""
function load_code_and_highlight(path::AbstractString)::String
    lines = readlines(path)
    code = [highlight_syntax(ln; style = true) for ln in lines]

    # clean
    clean(line) = replace(line, "    {/    }" => "")
    codelines = clean.(code)
    return join(codelines, "\n")
end
