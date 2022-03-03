
# ---------------------------------------------------------------------------- #
#                                     REGEX                                    #
# ---------------------------------------------------------------------------- #
# ---------------------------------- markup ---------------------------------- #
const OPEN_TAG_REGEX = r"\[[a-zA-Z _0-9. ,()#]+[^/\[]\]"
const CLOSE_TAG_REGEX = r"\[\/[a-zA-Z _0-9. ,()#]+[^/\[]\]"
const GENERIC_CLOSER_REGEX = r"\[\/\]"

"""
remove_markup

Removes all markup tags from a string of text.
"""
function remove_markup(input_text::AbstractString)::AbstractString
    text = input_text

    # remove extra closing tags
    text = replace(text, GENERIC_CLOSER_REGEX=>"")
    text = replace(text, CLOSE_TAG_REGEX=>"")

    return text
end

"""
    remove_markup_open(text::AbstractString)

Removes all opening markup tags from a piece of text
"""
remove_markup_open(text::AbstractString)::AbstractString = replace(text, OPEN_TAG_REGEX=>"")


# ----------------------------------- ansi ----------------------------------- #
const ANSI_REGEXEs = [
    r"\e\[[0-9]*m",
    r"\e\[[0-9;]*m",
]

"""
Removes all ANSI tags
"""
function remove_ansi(str::AbstractString)
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
Replaces each squared brackets with a double copy of itself
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
Repleces every double squared parenthesis with a double copy of itself
"""
function unescape_brackets(text::AbstractString)::AbstractString
    for (regex, replacement) in remove_brackets_regexes
        text = replace(text, regex=>replacement)
    end
    return text
end


# ---------------------------------------------------------------------------- #
#                                      I/O                                     #
# ---------------------------------------------------------------------------- #
"""
    read_file_lines(path::String, start::Int, stop::Int)

Reads a file and selects only lines in range start -> stop
"""
function read_file_lines(path::AbstractString, start::Int, stop::Int) 
    start = start < 1 ? 1 : start
    stop = stop >= countlines(path) ? countlines(path) : stop
    lines = readlines(path; keep=true)
    return [(n, ln) for (n, ln) in enumerate(lines)][start:stop]

end


# ---------------------------------------------------------------------------- #
#                                     MISC                                     #
# ---------------------------------------------------------------------------- #

"""
    replace_text(text::AbstractString, start::Int, stop::Int, replace::AbstractString)

Replaces a section of a string with another string
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

Replaces a section of a string with another string composed of repeats of a given character
"""
function replace_text(text::AbstractString, start::Int, stop::Int, char::Char='_')
    replacement = char^(stop-start-1)
    return replace_text(text, start, stop, replacement)
end

"""Removes all spaces from a string"""
nospaces(text::AbstractString) = replace(text, " " => "")

"""Removes all () brackets from a string"""
remove_brackets(text::AbstractString) = replace(replace(text, "("=>""), ")"=>"")

"""Removes spaces after commas """
unspace_commas(text::AbstractString) = replace(replace(text, ", "=>","), ". "=>".")

"""Splits a string into a vector of Chars"""
chars(text::AbstractString)::Vector{Char} = [x for x in text]

"""Merges a vector of strings in a single string"""
join_lines(lines::Vector) = join(lines, "\n")

join_lines(lines) = join(lines, "\n")

function split_lines(text::AbstractString)
    split(text, "\n")
end

function split_lines(renderable)
    if string(typeof(renderable)) == "Segment"
        return split_lines(renderable.text)
    else
        [s.text for s in renderable.segments]
    end
end

# ------------------------------- reshape text ------------------------------- #
function truncate(text::AbstractString, width::Int)
    if textlen(text) <= width
        return text
    end

    cut = get_last_valid_str_idx(text, width)
    return text[1:cut] * "..."
end

"""
recursively extracts character tags from tags
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

textlen(x) = (length ∘ remove_markup ∘ remove_markup_open ∘ remove_ansi)(x)

"""
    rehsape_text(text::AbstractString, width::Int)

Given a long string of text, it reshapes it into N lines
of fixed width
"""
function rehsape_text(text::AbstractString, width::Int; indent::Bool=true)::AbstractString    
    # get indentation spaces
    n_spaces = length(text) - length(strip(text))
    _indent = indent ? " "^n_spaces : ""

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

        push!(lines, text[1:cut])
        text = _indent * text[cut+1:end]
        j += cut

        # @info "\e[32mmade line" lines[end] cut j width length(text) len(text) text Measure(lines[end])
    end

    # add what's left of the text
    if length(text) > 0
        push!(lines, text)
    end

    # do checs and pad line
    for (n, line) in enumerate(lines)
        h = remove_markup(line)
        # @assert length(remove_markup(line)) <= width

        ll = length(remove_markup(line))
        if ll < width
            lines[n] = line * " "^(width-ll)
        end
    end
    # @info "lines" lines length(lines) lines[1] lines[2]
    # println("1 -----    ", lines[1])
    # println("2 -----    ", lines[2])
    # println("join   ", join_lines(pairup_tags(lines)))
    return join_lines(pairup_tags(lines))
end





# ------------------------------------ end ----------------------------------- #

"""
Applies a given function to each line in the text
"""
function do_by_line(fn, text::AbstractString)
    lines::Vector{AbstractString} = []
    for line in split_lines(text)
        push!(lines, fn(line))
    end
    return join_lines(lines)
end

do_by_line(fn, text::Vector) = do_by_line(fn, join_lines(text))

"""
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

function get_next_valid_str_idx(str::AbstractString, idx::Int, valid_places::Vector{Int64})
    while !isvalid(str, idx) || valid_places[idx] == 0
        idx += 1

        if idx == length(str)
            break
        end
    end
    return idx
end