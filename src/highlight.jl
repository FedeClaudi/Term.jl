import OrderedCollections: OrderedDict
import tree_sitter_julia_jll

using Highlights: Highlights

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
    code_style(capture::AbstractString)

Look up `capture` in `CodeTheme`, falling back to its closest ancestor capture.
"""
function code_style(capture::AbstractString)
    parts = split(capture, '.')
    while !isempty(parts)
        style = get(CodeTheme, join(parts, '.'), nothing)
        isnothing(style) || return style
        pop!(parts)
    end
    return CodeTheme["text"]
end

function print_code_segment(io::IO, code::AbstractString, style::AbstractString)
    for (i, line) in enumerate(split(code, '\n'))
        i > 1 && print(io, '\n')
        isempty(line) || print(io, "{$style}", escape_brackets(line), "{/$style}")
    end
    return
end

function render_code(io::IO, code::AbstractString)
    pos = 1
    for token in Highlights.highlight_tokens(tree_sitter_julia_jll, code)
        first_byte, last_byte = token.byte_range
        pos < first_byte && print_code_segment(
            io, SubString(code, pos, thisind(code, first_byte - 1)), CodeTheme["text"]
        )
        print_code_segment(io, token.text, code_style(token.capture))
        pos = last_byte + 1
    end
    pos ≤ ncodeunits(code) &&
        print_code_segment(io, SubString(code, pos), CodeTheme["text"])
    return
end

"""
    highlight_syntax(code::AbstractString; style::Bool=true) 

Highlight Julia code syntax in a string.
"""
function highlight_syntax(code::AbstractString; style::Bool = true)
    txt = sprint(render_code, code; context = stdout)
    style && (txt = do_by_line(apply_style, txt))
    return remove_markup(txt)
end

# Stack traces revisit the same few files across frames, and parsing dominates the cost.
const HIGHLIGHTED_FILES = Dict{Tuple{String, Float64}, Vector{String}}()
const HIGHLIGHTED_FILES_CACHE_SIZE = 32

"""
    highlight_file_lines(path::AbstractString)::Vector{String}

Highlight `path`, returning its styled lines. Parsing the whole file keeps each
line's enclosing block intact, which a line-at-a-time parse would cut apart.
"""
function highlight_file_lines(path::AbstractString)::Vector{String}
    length(HIGHLIGHTED_FILES) ≥ HIGHLIGHTED_FILES_CACHE_SIZE && empty!(HIGHLIGHTED_FILES)
    return get!(HIGHLIGHTED_FILES, (String(path), mtime(path))) do
        split_lines(highlight_syntax(join_lines(readlines(path)); style = true))
    end
end

"""
    load_code_and_highlight(path::AbstractString, lineno::Int; δ::Int=3, width::INt=120)

Load a file, get the code and format it. Return styled text
"""
function load_code_and_highlight(path::AbstractString, lineno::Int; δ::Int = 3)::String
    η = countlines(path)
    @assert lineno > 0 "lineno must be ≥1"
    @assert lineno ≤ η "lineno $lineno too high for file with $(η) lines"

    linenos = max(lineno - δ, 1):min(lineno + δ, η)
    codelines = highlight_file_lines(path)[linenos]
    δ == 0 && (codelines = lstrip_ansi.(codelines))

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
load_code_and_highlight(path::AbstractString)::String =
    join_lines(highlight_file_lines(path))
