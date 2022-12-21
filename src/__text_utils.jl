""" 
multiple strings replacement.
"""
function replace_multi(text::AbstractString, pairs::Pair...)::String
    VERSION ≥ v"1.7" && return replace(text, pairs...)
    VERSION < v"1.7" && begin
        for pair in pairs
            text = replace(text, pair)
        end
    end
    return text
end

plural(word::AbstractString, n) = n <= 1 ? word : word * 's'

# ---------------------------------------------------------------------------- #
#                                     REGEX                                    #
# ---------------------------------------------------------------------------- #
# ---------------------------------- markup ---------------------------------- #

"""
This regex uses lookahead and lookbehind to exclude {{
at the beginning of a tag, with this:
    (?<!\\{)\\[(?!\\{)
"""
RECURSIVE_OPEN_TAG_REGEX = r"\{(?:[^{}]*){2,}\}"
OPEN_TAG_REGEX = r"(?<!\{)\{(?!\{)[a-zA-Z _0-9. ,()#]*\}"
CLOSE_TAG_REGEX = r"\{\/[a-zA-Z _0-9. ,()#]+[^/\{]\}"
GENERIC_CLOSER_REGEX = r"(?<!\{)\{(?!\{)\/\}"

"""
    remove_markup(input_text::AbstractString)::AbstractString

Remove all markup tags from a string of text.
"""
function remove_markup(input_text; remove_orphan_tags = true)::String
    if remove_orphan_tags
        return replace_multi(
            input_text,
            OPEN_TAG_REGEX => "",
            GENERIC_CLOSER_REGEX => "",
            CLOSE_TAG_REGEX => "",
        )
    else
        # turn non-orphaned closing tags in opening tags before removing them
        for match in eachmatch(OPEN_TAG_REGEX, input_text)
            markup = match.match[2:(end - 1)]
            close = r"\{\/" * Regex(markup) * r"\}"
            input_text = replace(input_text, close => "{$markup}", count = 1)
        end
        return replace_multi(input_text, OPEN_TAG_REGEX => "", GENERIC_CLOSER_REGEX => "")
    end
end

""" 
    has_markup(text::String)

Returns `true` if `text` includes a `MarkupTag`
"""
has_markup(text)::Bool = occursin(OPEN_TAG_REGEX, text)

# ----------------------------------- ansi ----------------------------------- #
const ANSI_REGEXE = r"\e\[[0-9;]*m"

"""
    remove_ansi(input_text::AbstractString)::AbstractString

Remove all ANSI tags from a string of text
"""
remove_ansi(input_text)::String = replace(input_text, ANSI_REGEXE => "")

""" 
    has_ansi(text::String)

Returns `true` if `text` includes a `MarkupTag`
"""
has_ansi(text)::Bool = occursin(ANSI_REGEXE, text)

"""
    get_last_ANSI_code(text)::String

Get the last ANSI code in a sting, returns "" if no ANSI code found.
"""
function get_last_ANSI_code(text)::String
    has_ansi(text) || return ""

    # get the last matching regex
    rmatch = collect((eachmatch(ANSI_REGEXE, text)))[end]
    return rmatch.match
end

"""
    get_ANSI_codes(text)::String

Returns a string with all ANSI codes in the input.
"""
function get_ANSI_codes(text)::String
    has_ansi(text) || return ""
    matches = collect((eachmatch(ANSI_REGEXE, text)))
    return *(map(m -> m.match, matches)...)
end

"""
    replace_ansi(input_text)

Replace ANSI tags with ¦.

The number of '¦' matches the length of the ANSI tags.
Used when we want to hide ANSI tags but keep the string length intact.
"""
function replace_ansi(input_text)
    while occursin(rx, input_text) && (m = match(ANSI_REGEXE, input_text)) !== nothing
        input_text =
            replace_text(input_text, m.offset - 1, m.offset + length(m.match) - 1, '¦')
    end
    return input_text
end

ANSI_CLEANUP_REGEXES = [
    r"\e\[[0-9][0-9]m\e\[39m" => "",
    r"\e\[[0-9][0-9]m\e\[49m" => "",
    r"\e\[[0-9]m\e\[2[0-9]m" => "",
    r"\e\[22m\e\[22m" => "",
]

cleanup_ansi(text) = replace_multi(text, ANSI_CLEANUP_REGEXES...)

# --------------------------- clean text / text len -------------------------- #
"""
    cleantext(str::AbstractString)

Remove all style information from a string.
"""
cleantext(str)::String = (remove_ansi ∘ remove_markup)(str)

"""
    textlen(x::AbstractString)

Get length of text after all style information is removed.
"""
textlen(x; remove_orphan_tags = false)::Int =
    remove_markup(remove_ansi(x); remove_orphan_tags = remove_orphan_tags) |> textwidth

# --------------------------------- brackets --------------------------------- #
const brackets_regexes = [r"(?<!\{)\{(?!\{)", r"(?<!\})\}(?!\})"]

"""
    escape_brackets(text)::Stringremove_ansi(str)::String

Replace each curly bracket with a double copy of itself
"""
escape_brackets(text)::String =
    replace_multi(text, brackets_regexes[1] => "{{", brackets_regexes[2] => "}}")

const remove_brackets_regexes = [r"\{\{", r"\}\}"]

"""
    unescape_brackets(text)::String

Replece every double squared parenthesis with a single copy of itself
"""
unescape_brackets(text)::String = replace_multi(text, "{{" => "{", "}}" => "}")

unescape_brackets_with_space(text)::String = replace_multi(text, "{{" => " {", "}}" => "} ")

# ---------------------------------------------------------------------------- #
#                                      I/O                                     #
# ---------------------------------------------------------------------------- #
"""
    read_file_lines(path::String, start::Int, stop::Int)

Read a file and select only lines in range `start` -> `stop`.

Returns a vector of tuples with the line number and line content.
"""
function read_file_lines(path::AbstractString, start::Int, stop::Int)
    !isfile(path) && return nothing

    start = start < 1 ? 1 : start
    stop = stop ≥ countlines(path) ? countlines(path) : stop
    lines = readlines(path; keep = true)
    return collect(enumerate(lines))[start:stop]
end

# ---------------------------------------------------------------------------- #
#                                     MISC                                     #
# ---------------------------------------------------------------------------- #
"""
    tview(text, start::Int, stop::Int)

Get a view object with appropriate indices
"""
tview(text, start::Int, stop::Int) = view(text, thisind(text, start):thisind(text, stop))

"""
    replace_text(text::AbstractString, start::Int, stop::Int, replace::AbstractString)

Replace a section of a `text` between `start` and `stop` with `replace`.
"""
function replace_text(text, start::Int, stop::Int, replace::String)::String
    if start == 0
        return replace * text[(stop + 1):end]
    end

    start = isvalid(text, start) ? start : max(prevind(text, start), 1)
    return if start == 1
        text[1] * replace * text[(stop + 1):end]
    elseif stop == ncodeunits(text)
        text[1:start] * replace
    else
        text[1:start] * replace * text[(stop + 1):end]
    end
end

"""
    replace_text(text::AbstractString, start::Int, stop::Int, char::Char='_')

Replace a section of a `text`  between `start` and `stop` with another string composed of repeats of a given character `char`.
"""
function replace_text(text, start::Int, stop::Int, char::Char = '_')::String
    replacement = char^(stop - start)
    return replace_text(text, start, stop, replacement)
end

"""
    ltrim_str(str, width)

Cut a chunk of width `width` form the left of a string
"""
function ltrim_str(str, width)
    edge = nextind(str, 0, width)
    return if edge ≥ ncodeunits(str)
        str
    else
        str[1:edge]
    end
end

"""
    rtrim_str(str, width)

Cut a chunk of width `width` form the right of a string
"""
function rtrim_str(str, width)
    edge = nextind(str, 0, width)
    return str[edge:end]
end

"""
    nospaces(text::AbstractString)

Remove all spaces from a string.
"""
nospaces(text::AbstractString) = replace(text, " " => "")

"""
    remove_brackets(text::AbstractString)

Remove all () brackets from a string.
"""
remove_brackets(text)::String = replace_multi(text, "(" => "", ")" => "")

"""
    unspace_commas(text::AbstractString)

Remove spaces after commas.
"""
unspace_commas(text)::String = replace_multi(text, ", " => ",", ". " => ".")

"""
Split a string into a vector of Chars.
"""
chars(text::AbstractString)::Vector{Char} = collect(text)

"""
    join_lines(lines)

Merge a vector of strings in a single string.
"""
join_lines(lines::Vector{String})::String = join(lines, "\n")

"""
    split_lines(text::AbstractString)

Split a string into its composing lines.
"""
split_lines(text::String)::Vector{String} = split(text, "\n")
split_lines(text::SubString)::Vector{String} = String.(split(text, "\n"))

"""
    do_by_line(fn::Function, text::String)

Apply `fn` to each line in the `text`.

The function `fn` should accept a single `::String` argument.
"""
do_by_line(fn::Function, text::AbstractString)::String = join(fn.(split_lines(text)), "\n")

# ------------------------------- reshape text ------------------------------- #
"""
    fillin(text::String)::String

Ensure that each line in a multi-line text has the same width.
"""
function fillin(text; bg = nothing)::String
    lines = split_lines(text)
    length(lines) == 1 && return text

    w = max(map(textlen, lines)...)
    padline(ln) =
        if isnothing(bg)
            ln * " "^(w - textlen(ln))
        else
            ln * "{$bg}" * " "^(w - textlen(ln)) * "{/$bg}"
        end
    return join_lines(map(padline, lines))
end

"""
    str_trunc(text::AbstractString, width::Int)

Shorten a string of text to a target width
"""
function str_trunc(
    text::AbstractString,
    width::Int;
    trailing_dots = "...",
    ignore_markup = false,
)::String
    width < 0 && return text
    textlen(text) ≤ width && return text
    if contains(text, '\n')
        return do_by_line(
            l -> str_trunc(
                l,
                width;
                trailing_dots = trailing_dots,
                ignore_markup = ignore_markup,
            ),
            text,
        )
    end

    trunc =
        reshape_text(text, width - textwidth(trailing_dots); ignore_markup = ignore_markup)
    out = first(split_lines(trunc))
    textlen(out) == 0 && return out
    out[end] != ' ' && (out *= trailing_dots)
    return out
end

# ---------------------------------------------------------------------------- #
#                                     LINK                                     #
# ---------------------------------------------------------------------------- #

"""
    excise_link_display_text(link::String)

Given a link string of the form:
    "\x1b]8;;LINK_DESTINATION\x1b\\LINK_DISPLAY_TEXT\x1b]8;;\x1b\\"
this function returns "LINK_DISPLAY_TEXT" alone.
"""
function excise_link_display_text(link::AbstractString)
    parts = split(link, "\x1b\\")
    return if length(parts) > 1
        replace(parts[2], "\e]8;;" => "")
    else
        ""
    end
end

"""
    string_type(x)
Return the type of `x` if it's an AbstractString, else String
"""
string_type(x) = x isa AbstractString ? typeof(x) : String
