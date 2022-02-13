# ---------------------------------------------------------------------------- #
#                                    STRINGS                                   #
# ---------------------------------------------------------------------------- #

"""
    find_in_str("test", "my test")  # [4]
Returns the first index of when the string "search"
appears in the text.
"""
function find_in_str(search::String, text::String)
    indices = [f[1] for f in findall(search, text)]  # may contain invalid indices
end


"""Removes [()] from a string"""
remove_brackets(text::AbstractString) = replace(replace(replace(replace(text, "[" => ""), "]" => ""), "(" => ""), ")" => "")

"""Removes all spaces from a string"""
nospaces(text::String) = replace(text, " " => "")


"""
Converts a string to a vector of Char
"""
chars(str::AbstractString)::Vector{Char} = [c for c in str]

"""
Replaces:
    [[ with {
    ]] with }
    \e[ with {{
    \\033[ with {{{
"""
function escape_brackets(text::AbstractString)
    text = replace(text, "[[" => "{")
    text = replace(text, "}}" => "}")
    text = replace(text, "\e[" => "{{")
    text = replace(text, "\\033[" => "{{{")
    return text
end


function split_lines(text::AbstractString; discard_empty=true)
    if !discard_empty
        return split(text, "\n")
    else
        return [l for l in split(text, "\n") if length(l)>0]
    end
end

split_lines(renderable) = split_lines(renderable.string)

merge_lines(lines::Vector) = join(lines, "\n")

"""
When indexing a string, the number of indices is given by the
the sum of the `ncodeunits` of each `Char`, but some indices
will not be valid. This function ensures that given a (potentially)
not valid index, the last valid one is elected.
"""
function get_last_valid(str::AbstractString, idx::Int)
    while !isvalid(str, idx)
        idx -= 1

        if idx == 0
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
function get_next_valid(str::AbstractString, idx::Int)
    while !isvalid(str, idx)
        idx += 1

        if idx == length(str)
            throw("Failed to find a valid index for $str starting at $idx")
        end
    end
    return idx
end

# ---------------------------------------------------------------------------- #
#                                     REGEX                                    #
# ---------------------------------------------------------------------------- #

ANSI_OPEN_REGEX = r"\e\[0m"
ANSI_CLOSE_REGEX = r"\e\[[0-9]+\;[0-9]+\;[0-9]+[m]"

"""
Removes all ANSI tags
"""
strip_ansi(str::AbstractString) = replace(replace(str, ANSI_OPEN_REGEX => ""), ANSI_CLOSE_REGEX => "")


# ---------------------------------------------------------------------------- #
#                                   ITERABLES                                  #
# ---------------------------------------------------------------------------- #
"""
Returns an iterable yielding tuples (is_last, value)
where is_last == true only if value is the lest item in v.
"""
function loop_last(v::Vector)
    is_last = [i==length(v) for i in 1:length(v)]
    return zip(is_last, v)
end

