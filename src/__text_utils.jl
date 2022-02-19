
# ---------------------------------------------------------------------------- #
#                                     REGEX                                    #
# ---------------------------------------------------------------------------- #
# ---------------------------------- markup ---------------------------------- #
const OPEN_TAG_REGEX = r"\[[a-zA-Z _0-9.,()#]+[^/\[]\]"
const GENERIC_CLOSER_REGEX = r"\[\/\]"

"""
remove_markup

Removes all markup tags from a string of text.
"""
function remove_markup(input_text::AbstractString)::AbstractString
    text = input_text
    for regex in [OPEN_TAG_REGEX, GENERIC_CLOSER_REGEX]
        while occursin(regex, text)
            # get opening regex match
            rmatch = match(regex, text)

            # get closing regex with same markup
            markup = rmatch.match[2:end-1]
            close_regex = r"\[\/+" * markup * r"\]"

            # remove them
            text = replace(text, regex=>"")
            text = replace(text, close_regex=>"")
        end
    end

    return text
end

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


# ---------------------------------------------------------------------------- #
#                                     MISC                                     #
# ---------------------------------------------------------------------------- #
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

"""
    split_text_by_length(text::AbstractString, width::Int)

Splits a text such that each line has max length: width.
"""
function split_text_by_length(text::AbstractString, width::Int)
    if length(remove_ansi(remove_markup(text))) < width
        return text
    end

    n_cuts = (Int ∘ ceil)(length(text)/width)
    lines::Vector{AbstractString} = []

    for cut in 1:n_cuts
        pre = cut==1 ? 1 : get_last_valid_str_idx(text, width * (cut-1))
        
        if width * cut ≥ length(text)
            post = get_last_valid_str_idx(text, length(text))
        else
            post = get_last_valid_str_idx(text, width * cut - 1)
        end

        # ensure all lines have the same length
        line = text[pre:post]
        if length(line) < width
            line = line * " "^(width-length(line))
        end
        @assert length(line) == width
        
        push!(lines, line)

    end
    return join_lines(lines)
end

"""
Applies a given function to each line in the text
"""
function do_by_line(fn, text)
    lines::Vector{AbstractString} = []
    for line in split_lines(text)
        push!(lines, fn(line))
    end
    return join_lines(lines)
end

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