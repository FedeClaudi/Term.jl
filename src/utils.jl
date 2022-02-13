# ---------------------------------------------------------------------------- #
#                                    STRINGS                                   #
# ---------------------------------------------------------------------------- #

"""
    find_in_str("test", "my test")  # [4]
Returns the first index of when the string "search"
appears in the text.
"""
find_in_str(search::String, text::String) = [f[1] for f in findall(search, text)]

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
function escape_brackets(text::String)
    text = replace(text, "[[" => "{")
    text = replace(text, "}}" => "}")
    text = replace(text, "\e[" => "{{")
    text = replace(text, "\\033[" => "{{{")
    return text
end

# ---------------------------------------------------------------------------- #
#                                     REGEX                                    #
# ---------------------------------------------------------------------------- #

ANSI_OPEN_REGEX = r"\e\[0m"
ANSI_CLOSE_REGEX = r"\e\[[0-9]+\;[0-9]+\;[0-9]+[m]"

"""
Removes all ANSI tags
"""
strip_ansi(str::String) = replace(replace(str, ANSI_OPEN_REGEX => ""), ANSI_CLOSE_REGEX => "")


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

