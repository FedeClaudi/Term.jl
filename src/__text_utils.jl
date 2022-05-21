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
has_markup(text)::Bool = occursin(OPEN_TAG_REGEX, text)
                                        

# ----------------------------------- ansi ----------------------------------- #
const ANSI_REGEXE = r"\e\[[0-9;]*m"

"""
    remove_ansi(input_text::AbstractString)::AbstractString

Remove all ANSI tags from a string of text
"""
remove_ansi(input_text)::String = replace(input_text, ANSI_REGEXE => "", )


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
    return *(map(m->m.match, matches)...)
end


"""
    replace_ansi(input_text)

Replace ANSI tags with ¦.

The number of '¦' matches the length of the ANSI tags.
Used when we want to hide ANSI tags but keep the string length intact.
"""
function replace_ansi(input_text)
    while occursin(rx, input_text)
        mtch = match(ANSI_REGEXE, input_text)
        input_text = replace_text(input_text, mtch.offset-1, mtch.offset+length(mtch.match)-1, '¦')
    end
    return input_text
end


ANSI_CLEANUP_REGEXES = [
    r"\e\[[0-9][0-9]m\e\[39m"=>"",
    r"\e\[[0-9][0-9]m\e\[49m"=>"",
    r"\e\[[0-9]m\e\[2[0-9]m"=>"",
    r"\e\[22m\e\[22m"=>"",
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

unescape_brackets_with_space(text)::String = replace_multi(text, 
    remove_brackets_regexes[1]=>" [",
    remove_brackets_regexes[2]=>"] ",
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
    tview(text, start::Int, stop::Int)

Get a view object with appropriate indices
"""
tview(text, start::Int, stop::Int) = view(text,thisind(text, start):thisind(text, stop))
tview(text, start::Int, stop::Int, simple::Symbol) = view(text, start:stop)

"""
    replace_text(text::AbstractString, start::Int, stop::Int, replace::AbstractString)

Replace a section of a `text` between `start` and `stop` with `replace`.
"""
function replace_text(text, start::Int, stop::Int, replace::String)::String
    if start == 0
        return  replace * text[stop+1:end]
    end
    
    start = isvalid(text, start) ? start : max(prevind(text, start), 1)
    if start == 1
        return text[1] * replace * text[stop+1:end]
    elseif stop == ncodeunits(text)
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
    width < 0 && return text
    textlen(text) <= width && return text
    trunc = reshape_text(text, width-3)
    return split_lines(trunc)[1] * "..."
end

# ---------------------------------------------------------------------------- #
#                                 RESHAPE TEXT                                 #
# ---------------------------------------------------------------------------- #



"""
    reshape_text(text, width::Int)

Reshape a string to have max width when printed out.

Cut the string into multiple lines so that each line
has at most `width` when printed to terminal: ignoring
ANSI style but taking into account characters with
widths > 1. Text is preferentially split at a space
when possible to improve readability.
"""
function reshape_text(text, width::Int)
    if occursin("\n", text)
        return do_by_line(l -> reshape_text(l, width), text)
    end

    textlen(text) <= width && return text

    has_style = has_ansi(text) || has_markup(text)
    has_special = length(text) != ncodeunits(text)
    text = apply_style(text)

    chars::Vector{Union{Char, String}} = collect(text)
    L = length(chars)
    spaces::Vector{Bool} = Bool.(chars .== ' ')

    # get width at each char (ignoring ANSI codes)
    widths::Vector{Int} = textwidth.(chars)

    # ensure ANSI tags don't affect width
    if has_style
        for mtch in eachmatch(ANSI_REGEXE, text)
            if has_special
                # tag position in code units
                _i0 = mtch.offset 
                _i1 = mtch.offset + ncodeunits(mtch.match) - 1

                # tag position in characters
                i0 = length(text[1:_i0])
                i1 = length(text[_i0:_i1]) + i0 - 1
            else
                i0 = mtch.offset 
                i1 = mtch.offset + length(mtch.match) - 1
            end

            widths[i0:i1] .= 0
        end
    end

    cumwidths = cumsum(widths)
    cuts = findall(diff(mod.(cumwidths, width)) .< 0) .+ 1
    ncuts = length(cuts)
    n = 1
    while n <= length(cuts)
        cut = cuts[n]
        # @warn "processing cut $n: $cut"

        for i in 1:4
            if spaces[max(1, cut-i)] == true
                # get width of text excluded by new cut position
                if n < ncuts
                    # adjust cuts poisitions
                    Δw = cumwidths[cut] - cumwidths[cut-i]
                    newcuts = findall(
                        diff(
                            mod.(cumwidths .- cumwidths[cut] .+ Δw, width)
                            ) .< 0
                    )
                    
                    newcuts = newcuts[newcuts .> cut]
                    cuts = [cuts[1:n]..., newcuts...]
                end

                cut -= i
                break
            end
        end

        # make sure cut is at the end of an ANSI tag
        while cut < L && widths[cut+1] == 0
            cut -= 1
            cuts .-= 1
        end

        chars[cut] *= '\n'
        n += 1
    end

    # check that the last line has the right width
    if sum(widths[cuts[end]:end]) > width
        _chars = chars[cuts[end]+1:end]
        chars = chars[1:cuts[end]]
        append!(chars, collect(
                reshape_text(join(_chars), width)
                )
        )
    end
  
    # stitch it back together
    text = join(chars)
    lines = strip.(split(text, "\n"))

    # handle style
    if has_style
        styles = map(l -> get_ANSI_codes(l), lines)
        lines[1] *= "\e[0m"
        for i in 2:length(lines)
            lines[i] = cleanup_ansi(*(styles[1:i-1]...)) * lines[i] * "\e[0m"
        end
    end

    return chomp(cleanup_ansi(join(lines, "\n")))
end

