""" multiple strings replacement, for multiple on Julia version """
function replace_multi(text, pairs...) ::String
    VERSION >= v"1.7" && return replace(text, pairs...)
    VERSION < v"1.7" && begin
        for pair in pairs
            text = replace(text, pair)
        end
    end
    return text
end

# ---------------------------------------------------------------------------- #
#                                     REGEX                                    #
# ---------------------------------------------------------------------------- #
# ---------------------------------- markup ---------------------------------- #

"""
This regex uses lookahead and lookbehind to exclude [[
at the beginning of a tag, with this:
    (?<!\\[)\\[(?!\\[)
"""
const OPEN_TAG_REGEX = r"(?<!\[)\[(?!\[)[a-zA-Z _0-9. ,()#]*\]"
const CLOSE_TAG_REGEX = r"(?<!\[)\[(?!\[)\/[a-zA-Z _0-9. ,()#]+[^/\[]\]"
const GENERIC_CLOSER_REGEX = r"(?<!\[)\[(?!\[)\/\]"

"""
    remove_markup(input_text::AbstractString)::AbstractString

Remove all markup tags from a string of text.
"""
remove_markup(input_text)::String = replace_multi(input_text, 
                                        OPEN_TAG_REGEX => "", 
                                        GENERIC_CLOSER_REGEX => "", 
                                        CLOSE_TAG_REGEX => ""
                                            )

""" 
    has_markup(text::String)

Returns `true` if `text` includes a `MarkupTag`
"""
has_markup(text::String)::Bool = occursin(OPEN_TAG_REGEX, text)
                                        

# ----------------------------------- ansi ----------------------------------- #
const ANSI_REGEXEs = [r"\e\[[0-9]*m", r"\e\[[0-9;]*m"]

"""
    remove_ansi(input_text::AbstractString)::AbstractString

Remove all ANSI tags from a string of text
"""
remove_ansi(input_text)::String = replace_multi(input_text, 
                                    ANSI_REGEXEs[1] => "", 
                                    ANSI_REGEXEs[2] => ""
                                    )


""" 
    has_markup(text::String)

Returns `true` if `text` includes a `MarkupTag`
"""
has_ansi(text::String)::Bool = occursin(ANSI_REGEXEs[1], text) || occursin(ANSI_REGEXEs[2], text)

"""
    get_last_ANSI_code(text)::String

Get the last ANSI code in a sting, returns "" if no ANSI code found.
"""
function get_last_ANSI_code(text)::String
    has_ansi(text) || return ""

    # get the last matching regex
    m1 = collect((eachmatch(ANSI_REGEXEs[1], text)))[end]
    m2 = collect((eachmatch(ANSI_REGEXEs[2], text)))[end]
    
    rmatch = m1.offset > m2.offset ? m1 : m2
    return rmatch.match
end

"""
    replace_ansi(input_text)

Replace ANSI tags with ¦.

The number of '¦' matches the length of the ANSI tags.
Used when we want to hide ANSI tags but keep the string length intact.
"""
function replace_ansi(input_text)
    for rx in ANSI_REGEXEs
        while occursin(rx, input_text)
            mtch = match(rx, input_text)
            input_text = replace_text(input_text, mtch.offset-1, mtch.offset+length(mtch.match)-1, '¦')
        end
    end
    return input_text
end


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
textlen(x::String)::Int = (textwidth ∘ remove_markup ∘ remove_ansi)(x)
textlen(x::SubString)::Int = (textwidth ∘ remove_markup ∘ remove_ansi)(x)



# --------------------------------- brackets --------------------------------- #
const brackets_regexes = [
    r"(?<!\[)\[(?!\[)",
    r"(?<!\])\](?!\])",
]

"""
    remove_ansi(str)::String

Replace each squared bracket with a double copy of itself
"""
escape_brackets(text)::String = replace_multi(text, 
        brackets_regexes[1]=>"[[",
        brackets_regexes[2]=>"]]",
)

const remove_brackets_regexes = [
    r"\[\[",
    r"\]\]",
]

"""
    unescape_brackets(text)::String

Replece every double squared parenthesis with a single copy of itself
"""
unescape_brackets(text)::String = replace_multi(text, 
    remove_brackets_regexes[1]=>"[",
    remove_brackets_regexes[2]=>"]",
)


# ---------------------------------------------------------------------------- #
#                                      I/O                                     #
# ---------------------------------------------------------------------------- #
"""
    read_file_lines(path::String, start::Int, stop::Int)

Read a file and select only lines in range `start` -> `stop`.

Returns a vector of tuples with the line number and line content.
"""
function read_file_lines(path::AbstractString, start::Int, stop::Int)
    start = start < 1 ? 1 : start
    stop = stop >= countlines(path) ? countlines(path) : stop
    lines = readlines(path; keep = true)
    return collect(enumerate(lines))[start:stop]
end

# ---------------------------------------------------------------------------- #
#                                     MISC                                     #
# ---------------------------------------------------------------------------- #

"""
    replace_text(text::AbstractString, start::Int, stop::Int, replace::AbstractString)

Replace a section of a `text` between `start` and `stop` with `replace`.
"""
function replace_text(text, start::Int, stop::Int, replace::String)::String
    # start = max(prevind(text, start), 1)
    start = isvalid(text, start) ? start : max(prevind(text, start), 1)
    # stop = min(nextind(text, stop+1), ncodeunits(text))
    if start == 1
        return replace * text[stop+1:end]
    elseif stop == length(text)
        return text[1:start] * replace
    else
        return text[1:start] * replace * text[stop+1:end]
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
join_lines(lines::Vector)::String = join(lines, "\n")
join_lines(lines...) = join(lines, "\n")

"""
    split_lines(text::AbstractString)

Split a string into its composing lines.
"""
split_lines(text::String)::Vector{String} = split(text, "\n")
split_lines(text::SubString)::Vector{String} = String.(split(text, "\n"))


"""
    split_lines(renderable)

Split a renderable's text.
"""
function split_lines(renderable)
    string(typeof(renderable)) == "Segment" && return split_lines(renderable.text)
    return [s.text for s in renderable.segments]

end

# ------------------------------- reshape text ------------------------------- #
"""
    fillin(text::String)::String

Ensure that each line in a multi-line text has the same width.
"""
function fillin(text)::String
    lines = split_lines(text)
    length(lines) == 1 && return text

    w = max(map(textlen, lines)...)
    return join_lines(map(
        (ln) -> ln * " "^(w - textlen(ln)),
        lines
    ))
end


"""
    truncate(text::AbstractString, width::Int)

Shorten a string of text to a target width
"""
function truncate(text::AbstractString, width::Int)
    textlen(text) <= width && return text
    return text[1:prevind(text, width - 2)] * "..."
end


"""
cutline_nospaces(line, width::Int)

Cut a line to a width, without using spaces for cut. 
It ignores ANSI codes to get the right width.
"""
function cutline_nospaces(line, width::Int)
    idx = width
    while textlen(line[1:idx]) < width
        idx += 1
    end

    cut = prevind(line, idx)
    return line[1:cut], line[cut+1:end]
end

"""
    reshape_line_no_markup(line, width::Int)::String

Reshapes a line to be a multi-line string with given width.

When reshaping a line with no markup we don't need to worry
about breaking ANSI tags and we can split the text at a 
convenient space or in the middle of a word if not possible.
"""
function reshape_line_no_markup(line, width::Int)::String
    splitted = ""
    while textwidth(line) > width
        cut = findlast(' ' , first(line, width))
        cut = isnothing(cut) ? prevind(line, width) : cut
        splitted *= line[1:cut] * " \n"
        line = line[cut+1:end]
    end
    return chomp(splitted * line)
end

"""
    get_valid_cut_idx(shortline)::Int

Get a string cut idx not in an ANSI tag.

When reshaping a string line with ANSI information, if 
no valid space is found for cutting we need to split
a word. This function chooses a cutting point not in
an ANSI tag to preserve style info
"""
function get_valid_cut_idx(line, width)::Int
    textlen(line) <= width && return length(line)

    # get a short line with no ANSI
    shortline = replace_ansi(line[1:prevind(line, width)])

    # get the last non-ansi char in shortline
    idx = findlast(c -> c != '¦', collect(shortline))
    isnothing(idx) || return prevind(
        shortline, 
        idx
    )

    return length(shortline)
end

"""
    get_spaces_locations(shortline)

Given a string with ANSI codes, returns the location
of ' ' as the width of the string up to that point
as printed out (i.e. no ANSI tags)
"""
function get_spaces_locations(line)::Tuple{Vector{Int}, Vector{Int}}
    spaces = findall(' ', line)
    locs = map(s -> textlen(line[1:s]), spaces)
    return spaces, locs
end

"""
    reshape_line(line, width::Int)

Reshape a line with ANSI style to be of a given width.

This needs to be done more carefully than if we didn't
have ANSI to avoid braking the style info.
"""
function reshape_line(line, width::Int)
    splitted = ""
    while textwidth(line) > width
        spaces, locs = get_spaces_locations(line)
        cut = findlast(locs .<= width)
        cut = isnothing(cut) ? get_valid_cut_idx(line, width) : spaces[cut]

        pre = line[1:cut]
        ansi = get_last_ANSI_code(pre)
        splitted *=pre * "\e[0m\n"
        line = ansi * line[cut+1:end]
    end
    return chomp(splitted * line)
end


"""
    reshape_text(text::String, width::Int)

Reshape `text` to have a given `width`.

When `text` is longer than `width`, it gets cut into multiple lines.
This is done carefully to preserve style information. Markup
style is applied to get ANSI tags and the text is cut to avoid 
breaking the tags.
"""
function reshape_text(text::String, width::Int)::String
    # check if no work is required
    textlen(text) <= width && return text

    with_mkup = has_markup(text)

    text = with_mkup ? apply_style(text) : text
    reshape_fn = with_mkup ? reshape_line : reshape_line_no_markup
    return do_by_line(
        line -> reshape_fn(line, width), text
    )
end


"""
    do_by_line(fn::Function, text::String)

Apply `fn` to each line in the `text`.

The function `fn` should accept a single `::String` argument.
"""
function do_by_line(fn::Function, text)::String
    out = ""
    for (last, line) in loop_last(split_lines(text))
        out *= fn(line) * (last ? "" : "\n")
    end
    return out
end

do_by_line(fn::Function, text::Vector)::String = join_lines(fn.(text))
