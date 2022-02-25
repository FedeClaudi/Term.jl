
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
            text = replace(text, "[$markup]"=>"")
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

"""
    rehsape_text(text::AbstractString, width::Int)

Given a long string of text, it reshapes it into N lines
of fixed width
"""
function rehsape_text(text::AbstractString, width::Int)
    tags = extract_markup(text)

    in_tags = zeros(Int, length(text))
    valid_chars = ones(Int, length(text))
    for tag in tags

        in_tags[tag.open.stop + 1 : tag.close.start-1] .= -1

        valid_chars[tag.open.start:tag.open.stop] .= 0
        valid_chars[tag.close.start : tag.close.stop] .= 0
    end
    tag_start = [t.open.start for t in tags]


    lines = []
    j = 1
    next_ln_start = ""
    while length(remove_markup(text))>width
        # get a cutting index not in a tag's markup
        line = ""
        cut = findlast(cumsum(valid_chars[j : end]) .<= width)
        cut = isnothing(cut) ? length(text) : cut
        
        # when splitting a tag, replicated start/end for new lines
        if in_tags[cut+j] == -1
            pre = findlast(tag_start .<= j)
            pre = isnothing(pre) ? 1 : pre

            next_ln_start = "[$(tags[pre].open.markup)]"
            ln_end = "[$(tags[pre].close.markup)]"
        else
            next_ln_start, ln_end = "", ""
        end

        # prep line
        line =  next_ln_start * text[1:cut] * ln_end


        push!(lines, line)
        text = text[cut+1:end]
        j += cut

    end

    # add what's left of the text
    if length(text) > 0
        push!(lines, next_ln_start * text)
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