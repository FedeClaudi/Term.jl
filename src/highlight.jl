using Highlights.Format
import Highlights: Lexers
import Highlights
import OrderedCollections: OrderedDict

# ------------------------------- highlighting ------------------------------- #
highlight_regexes = OrderedDict(
    :number => (
        r"(?<group>(?<![a-zA-Z0-9_])\d+(\.\d*)?+([eE][+-]?\d*)?)", 
        ),
    :operator => (r"(?<group>(?<!\{)\/)", r"(?<group>[\+\-\*\%\^\&\|\!\=\>\<\~])"),

    :string => (r"(?<group>[\"\'](\n|.)*?[\"\'])", ),
    :code => (r"(?<group>([\`]{3}|[\`]{1})(\n|.)*?([\`]{3}|[\`]{1}))", ),
    # :code => (r"(?<group> [\`]{1}(\n|.)+?[\`]{1})", ),
    :expression => (r"(?<group>\:\(+.+[\)])", ),
    :symbol => (r"(?<group>\:\w+)", ),
    :emphasis_light => (r"(?<group>[\,\[\]])", ),
)



"""
    highlight(text::AbstractString, theme::Theme)

Highlighs a text introducing markup to style semantically
relevant segments, colors specified by a theme object
"""
function highlight(text::AbstractString; theme::Theme=theme)   
    has_markup(text) && return text
    
    # highlight with regexes 
    for (symb, rxs) in pairs(highlight_regexes)
        markup = getfield(theme, symb)
        open, close = "{$markup}", "{/$markup}"
        for rx in rxs
            text = replace(
                text, 
                rx => SubstitutionString(open * s"\g<0>" * close)
                )
        end
    end


    return apply_style(text)
end

"""
    highlight(text::AbstractString, theme::Theme, like::Symbol)

Hilights an entire text as if it was a type of semantically
relevant text of type :like.
"""
function highlight(text::AbstractString, like::Symbol; theme::Theme=theme)
    markup = getfield(theme, like)
    return apply_style(do_by_line((x)->"{"*markup*"}"*x*"{/"*markup*"}", chomp(text)))
end

# shorthand to highlight objects based on type
highlight(x::Union{UnionAll, DataType}; theme::Theme=theme) = highlight(string(x), :type; theme=theme)
highlight(x::Number; theme::Theme=theme) = highlight(string(x), :number; theme=theme)
highlight(x::Function; theme::Theme=theme) = highlight(string(x), :func; theme=theme)
highlight(x::Symbol; theme::Theme=theme) = highlight(string(x), :symbol; theme=theme)
highlight(x::Expr; theme::Theme=theme) = highlight(string(x), :expression; theme=theme)
highlight(x::AbstractVector; theme::Theme=theme) = highlight(string(x), :number; theme=theme)

highlight(x; theme=theme) = string(x)  # capture all other cases


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

    if style
        txt = apply_style(txt)
    end

    return txt
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
    linenos = [ln[1] for ln in lines]
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
        if n == lineno
            symb = "{red bold}❯{/red bold}"
            color = "white"
        else
            symb = " "
            color = "grey39"
        end

        # end
        line = textlen(line) > 1 ? lpad(line[dedent:end], 8) : line
        line = symb * " {$color}$n{/$color} " * line
        push!(cleaned_lines, line)
    end

    return join(cleaned_lines, "\n")
end
