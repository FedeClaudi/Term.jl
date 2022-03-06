
# ---------------------------------------------------------------------------- #
#                                     REGEX                                    #
# ---------------------------------------------------------------------------- #
# ---------------------------------- markup ---------------------------------- #
const OPEN_TAG_REGEX = r"\[[a-zA-Z _0-9. ,()#]+[^/\[]\]"
const CLOSE_TAG_REGEX = r"\[\/[a-zA-Z _0-9. ,()#]+[^/\[]\]"
const GENERIC_CLOSER_REGEX = r"\[\/\]"

"""
    remove_markup(input_text::AbstractString)::AbstractString

Remove all markup tags from a string of text.
"""
function remove_markup(input_text::AbstractString)::AbstractString
    text = replace_double_brackets(input_text)

    # remove extra closing tags
    text = remove_markup_open(text)
    text = replace(text, GENERIC_CLOSER_REGEX=>"")
    text = replace(text, CLOSE_TAG_REGEX=>"")

    return reinsert_double_brackets(text)
end

"""
    remove_markup_open(text::AbstractString)

Remove all opening markup tags from a string of text
"""
remove_markup_open(text::AbstractString)::AbstractString = replace(text, OPEN_TAG_REGEX=>"")


# ----------------------------------- ansi ----------------------------------- #
const ANSI_REGEXEs = [
    r"\e\[[0-9]*m",
    r"\e\[[0-9;]*m",
]

"""
    remove_ansi(str::AbstractString)::AbstractString

Remove all ANSI tags from a string of text
"""
function remove_ansi(str::AbstractString)::AbstractString
    for regex in ANSI_REGEXEs
        str = replace(str, regex => "")
    end
    str
end


# --------------------------------- brackets --------------------------------- #
const brackets_regexes = [
    (r"\[", "[["), (r"\]", "]]")
]

"""
    remove_ansi(str::AbstractString)::AbstractString

Replace each squared bracket with a double copy of itself
"""
function escape_brackets(text::AbstractString)::AbstractString
    for (regex, replacement) in brackets_regexes
        text = replace(text, regex=>replacement)
    end
    return text
end

const remove_brackets_regexes = [
    (r"\[\[", "["), (r"\]\]", "]")
]

"""
    unescape_brackets(text::AbstractString)::AbstractString

Replece every double squared parenthesis with a single copy of itself
"""
function unescape_brackets(text::AbstractString)::AbstractString
    for (regex, replacement) in remove_brackets_regexes
        text = replace(text, regex=>replacement)
    end
    return text
end

"""
    replace_double_brackets(text::AbstractString)::AbstractString

Replace double brackets with %% and ±± to avoid them being picked up by markup extraction
"""
function replace_double_brackets(text::AbstractString)::AbstractString
    text = replace(text, "[["=>"%%")
    text = replace(text, "]]"=>"±±")
    return text
end

"""
    reinsert_double_brackets(text::AbstractString)::AbstractString

Insert previously replaced double brackets
"""
function reinsert_double_brackets(text::AbstractString)::AbstractString
    text = replace(text, "%%"=>"[[")
    text = replace(text, "±±"=>"]]")
    return text
end

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
    lines = readlines(path; keep=true)
    return collect(enumerate(lines))[start:stop]
end


# ---------------------------------------------------------------------------- #
#                                     MISC                                     #
# ---------------------------------------------------------------------------- #

"""
    replace_text(text::AbstractString, start::Int, stop::Int, replace::AbstractString)

Replace a section of a `text` between `start` and `stop` with `replace`.
"""
function replace_text(text::AbstractString, start::Int, stop::Int, replace::AbstractString)
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
function replace_text(text::AbstractString, start::Int, stop::Int, char::Char='_')
    replacement = char^(stop-start-1)
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
remove_brackets(text::AbstractString) = replace(replace(text, "("=>""), ")"=>"")

"""
    square_to_round_brackets(text::AbstractString)

Replace square brackets with round ones.
"""
square_to_round_brackets(text::AbstractString) = replace(replace(text, "["=>"("), "]"=>")")

"""
    unspace_commas(text::AbstractString)

Remove spaces after commas.
"""
unspace_commas(text::AbstractString) = replace(replace(text, ", "=>","), ". "=>".")

"""
Split a string into a vector of Chars.
"""
chars(text::AbstractString)::Vector{Char} = [x for x in text]

"""
    join_lines(lines)

Merge a vector of strings in a single string.
"""
join_lines(lines) = join(lines, "\n")

"""
    split_lines(text::AbstractString)

Split a string into its composing lines.
"""
function split_lines(text::AbstractString)
    split(text, "\n")
end

"""
    split_lines(renderable)

Split a renderable's text.
"""
function split_lines(renderable)
    if string(typeof(renderable)) == "Segment"
        return split_lines(renderable.text)
    else
        [s.text for s in renderable.segments]
    end
end

# ------------------------------- reshape text ------------------------------- #
"""
    truncate(text::AbstractString, width::Int)

Shorten a string of text to a target width
"""
function truncate(text::AbstractString, width::Int)
    if textlen(text) <= width
        return text
    end

    cut = get_last_valid_str_idx(text, width-3)
    return text[1:cut] * "..."
end

"""
    get_valid_chars!(valid_chars::Vector{Int}, tag, δ::Int)

Recursively extract valid characters (i.e. not in markup tags) from a string.
"""
function get_valid_chars!(valid_chars::Vector{Int}, tag, δ::Int)
    # get correct start/stop positions
    s1, e1 = δ+tag.open.start, δ+tag.open.stop
    s2, e2 = δ+tag.close.start, δ+tag.close.stop


    # do nested tags
    for inner in tag.inner_tags
        get_valid_chars!(valid_chars, inner, e1)
    end

    if s2 > length(valid_chars)
        @warn "How can tag close after valid chars?" tag tag.open tag.close length(valid_chars) tag.text
    else
        valid_chars[s1 : e1] .= 0
        valid_chars[s2 : e2] .= 0
    end
    
    return valid_chars
end

"""
    textlen(x::AbstractString)

Get length of text after all style information is removed.
"""
textlen(x::AbstractString) = (length ∘ remove_markup ∘ remove_markup_open ∘ remove_ansi)(x)

"""
    reshape_text(text::AbstractString, width::Int)

Reshape `text` to have a given `width`.

When `text` is longer than `width`, it gets cut into multiple lines.
This is done carefully to preserve style information by: avoiding 
cutting inside style markup and copying markup tags over to new lines
so that the style is correctly applied.
"""
function reshape_text(text::AbstractString, width::Int)::AbstractString    
    # check if no work is required
    if textlen(text) <= width
        return text
    end


    # extract tag and mark valid characters and "cutting" places
    tags = extract_markup(text)
    valid_chars = ones(Int, length(text))
    for tag in tags
        get_valid_chars!(valid_chars, tag, 0)
    end

    # ? debug: print label for each char
    # @info "Reshaping" text len(text) width tags length(valid_chars)
    # for (n, (ch, vl)) in enumerate(zip(text[1:49], valid_chars[1:49]))
    #     color = vl == 1 ? "\e[32m" : "\e[31m"
    #     println("($n)  \e[34m$ch\e[0m - valid: $color$vl\e[0m)")
    # end

    # create lines with splitted tex
    lines::Vector{AbstractString} = []
    j = 1
    while textlen(text)>width

        # get a cutting index not in a tag's markup
        condition = (cumsum(valid_chars[j : end]) .<= width) .& valid_chars[j : end] .==1
        cut = findlast(condition)
        if cut+j > length(valid_chars)
            @warn "ops not valid" j cut length(valid_chars)
            cut = length(valid_chars) - j
        end

        # prep line
        try
            push!(lines, lstrip(text[1:cut]))
            text = text[cut+1:end]
            j += cut
        catch err
            throw("Failed to reshape text: $err - target width: $width")
        end
    end

    # add what's left of the text
    if length(text) > 0
        push!(lines, text)
    end

    # do checks and pad line
    for (n, line) in enumerate(lines)
        h = remove_markup(line)
        # @assert length(remove_markup(line)) <= width

        ll = length(remove_markup(line))
        if ll < width
            lines[n] = line * " "^(width-ll)
        end
    end
    
    return join_lines(pairup_tags(lines))
end





# ------------------------------------ end ----------------------------------- #

"""
    do_by_line(fn::Function, text::AbstractString)

Apply `fn` to each line in the `text`.

The function `fn` should accept a single `::AbstractString` argument.
"""
function do_by_line(fn::Function, text::AbstractString)
    lines::Vector{AbstractString} = []
    for line in split_lines(text)
        push!(lines, fn(line))
    end
    return join_lines(lines)
end

do_by_line(fn, text::Vector) = do_by_line(fn, join_lines(text))

"""
    get_last_valid_str_idx(str::AbstractString, idx::Int)

Get valid index to cut a string at.

When indexing a string, the number of indices is given by the
the sum of the `ncodeunits` of each `Char`, but some indices
will not be valid. This function ensures that given a (potentially)
not valid index, the last valid one is elected.
"""
function get_last_valid_str_idx(str::AbstractString, idx::Int)
    while !isvalid(str, idx)
        idx -= 1

        if idx <= 0
            throw("Failed to find a valid index for $str starting at $idx")
        end
    end
    return idx
end

function get_last_valid_str_idx(str::AbstractString, idx::Int, valid_places::Vector{Int64})
    while !isvalid(str, idx) || valid_places[idx]==0
        idx -= 1

        if idx == 0
            break
        end
    end
    return idx
end


"""
get_next_valid_str_idx(str::AbstractString, idx::Int)

Get valid index to cut a string at.

When indexing a string, the number of indices is given by the
the sum of the `ncodeunits` of each `Char`, but some indices
will not be valid. This function ensures that given a (potentially)
not valid index, the next valid one is elected.
"""
function get_next_valid_str_idx(str::AbstractString, idx::Int)
    while !isvalid(str, idx)
        idx += 1

        if idx >= length(str)
            throw("Failed to find a valid index for $str starting at $idx")
        end
    end
    return idx
end