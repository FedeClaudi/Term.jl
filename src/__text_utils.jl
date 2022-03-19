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
    cleantext(str::AbstractString)

Remove all style information from a string.
"""
cleantext(str)::String = (remove_ansi ∘ remove_markup)(str)

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
function replace_text(text, start::Int, stop::Int, replace)::String
    if start == 1
        return replace * text[stop:end]
    elseif stop == length(text)
        return text[1:start] * replace
    else
        return text[1:start] * replace * text[stop:end]
    end
end

"""
    replace_text(text::AbstractString, start::Int, stop::Int, char::Char='_')

Replace a section of a `text`  between `start` and `stop` with another string composed of repeats of a given character `char`.
"""
function replace_text(text, start::Int, stop::Int, char::Char = '_')::String
    replacement = char^(stop - start - 1)
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
unspace_commas(text)::String = square_to_round_brackets(text, ", " => ",", ". " => ".")

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
    return text[1:prevind(text, width - 3)] * "..."
end

"""
    get_valid_chars!(valid_chars::Vector{Int}, tag, δ::Int)

Recursively extract valid characters (i.e. not in markup tags) from a string.
"""
function get_valid_chars!(valid_chars::Vector{Int}, tag, δ::Int)
    # get correct start/stop positions
    s1, e1 = δ + tag.open.start, δ + tag.open.stop
    s2, e2 = δ + tag.close.start, δ + tag.close.stop

    # do nested tags
    for inner in tag.inner_tags
        get_valid_chars!(valid_chars, inner, e1)
    end

    if s2 > length(valid_chars)
        @debug "How can tag close after valid chars?" tag tag.open tag.close length(
            valid_chars
        ) tag.text
    else
        valid_chars[s1:e1] .= 0
        valid_chars[s2:e2] .= 0
    end

    return valid_chars
end

"""
    textlen(x::AbstractString)

Get length of text after all style information is removed.
"""
textlen(x::String)::Int = (textwidth ∘ remove_markup ∘ remove_ansi)(x)
textlen(x::SubString)::Int = (textwidth ∘ remove_markup ∘ remove_ansi)(x)


"""
    reshape_text(text::String, width::Int)

Reshape `text` to have a given `width`.

When `text` is longer than `width`, it gets cut into multiple lines.
This is done carefully to preserve style information by: avoiding 
cutting inside style markup and copying markup tags over to new lines
so that the style is correctly applied.
"""
function reshape_text(text::String, width::Int)::String
    # check if no work is required
    if textlen(text) <= width
        return text
    end

    # extract tag and mark valid characters and "cutting" places
    tags = extract_markup(text)
    valid_chars = ones(Int, length(text))
    spaces = isspace.(chars(text))
    for tag in tags
        get_valid_chars!(valid_chars, tag, 0)
    end

    # create lines with splitted tex
    lines::Vector{String} = []
    j = 1
    while textlen(text) > width
        # get a cutting index not in a tag's markup
        condition = (cumsum(valid_chars[j:end]) .<= width) .& valid_chars[j:end] .== 1 .& spaces[j:end] .== 1
        cut = findlast(condition)

        if isnothing(cut)
            # couldnt find a cut in the spaces, try without
            condition = (cumsum(valid_chars[j:end]) .<= width) .& valid_chars[j:end] .== 1
            cut = findlast(condition)
        end

        if cut + j > length(valid_chars)
            @warn "ops not valid" j cut length(valid_chars)
            cut = length(valid_chars) - j
        end

        # prep line
        try
            newline = text[1:cut]

            # pad new line with spaces to ensure it has the right lengt
            newline *= " ".^(width - textlen(newline))

            push!(lines, newline)
            text = lstrip(text[(cut + 1):end])
            j += cut
        catch err
            throw("Failed to reshape text: $err - target width: $width")
        end
    end

    # add what's left of the text
    if length(text) > 0
        push!(lines, text * " "^(width - textlen(text)))
    end

    # do checks and pad line
    for (n, line) in enumerate(lines)
        h = remove_markup(line)
        # @assert length(remove_markup(line)) <= width

        ll = length(remove_markup(line))
        if ll < width
            lines[n] = line * " "^(width - ll)
        end
    end

    return join_lines(pairup_tags(lines))
end

# ------------------------------------ end ----------------------------------- #

"""
    do_by_line(fn::Function, text::String)

Apply `fn` to each line in the `text`.

The function `fn` should accept a single `::String` argument.
"""
function do_by_line(fn::Function, text::String)::String
    out = ""
    for (last, line) in loop_last(split_lines(text))
        out *= fn(line) * (last ? "" : "\n")
    end
    return out
end

do_by_line(fn::Function, text::Vector)::String = join_lines(fn.(text))
