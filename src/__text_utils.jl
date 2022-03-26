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
const ANSI_REGEXE = r"\e\[[0-9;]*m"

"""
    remove_ansi(input_text::AbstractString)::AbstractString

Remove all ANSI tags from a string of text
"""
remove_ansi(input_text)::String = replace(input_text, ANSI_REGEXE => "", )


""" 
    has_markup(text::String)

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
    textlen(text) <= width && return text
    return text[1:prevind(text, width - 2)] * "..."
end

# ---------------------------------------------------------------------------- #
#                                 RESHAPE TEXT                                 #
# ---------------------------------------------------------------------------- #

"""
Store information about the location and style of an ansi tag
"""
struct AnsiTag
    start::Int
    stop::Int
    style::SubString
end

"""
    excise_style(text)::Tuple{String, Vector{AnsiTag}, Bool}

Cut ANSI style information out of a string and store ANSI tags locations.
"""
function excise_style(text)::Tuple{String, Vector{AnsiTag}, Bool}
    hasstyle = has_markup(text) || has_ansi(text)
    text = apply_style(text)

    tags::Vector{AnsiTag} = []
    while occursin(ANSI_REGEXE, text)
        mtch = match(ANSI_REGEXE, text)
        _start = thisind(text, max(mtch.offset-1, 1))
        _stop = thisind(text, mtch.offset + length(mtch.match))
        
        push!(tags, AnsiTag(_start, _stop, mtch.match))
        text = text[1:_start] * text[_stop:end]
    end

    return text, tags, hasstyle
end


"""
    reinject_style(text, tags::Vector{AnsiTag}, cuts::Vector{Int})

Re-insert previously excised ANSI style tags.
If the cleaned text was reshaped, `cuts` stores information about
where new lines were added so that the ANSI style can be added
in the right place.
"""
function reinject_style(text, tags::Vector{AnsiTag}, cuts::Vector{Int})
    issimple = length(text) == ncodeunits(text)
    for tag in reverse(tags)
        pads = findall(cuts .< tag.start)
        pads = isnothing(pads) ? 0 : max(0, length(pads)-1)

        if issimple
            cut1 = tag.start + pads
            cut2 = cut1+1
        else
            cut1 = thisind(text, tag.start+pads)
            cut2 = thisind(text, cut1+ncodeunits(text[cut1]))
        end
        cut1 > ncodeunits(text) && continue
        cut2 = min(cut2, ncodeunits(text))

        text = text[1:cut1] * tag.style * text[cut2:end]

    end
    return text
end

"""
    correct_newline_style(text)

Given a multi-line text with ANSI style, add an ANSI close
tag at the end of each line and restore the style in the next.

This is important for reshaped text that needs to be put in
layouts with other text and you don't want the ANSI style
to bleed into other renderables.
"""
function correct_newline_style(text)
    ansi = ""
    out = ""
    for (last, line) in loop_last(split(text, "\n"))
        out *= ansi * line * (last ? "\e[0m" : "\e[0m\n")
        ansi = last ? "" : get_ANSI_codes(line)
    end
    out
end

"""
    get_text_info(text) 

Extract a bunch of information from a string of text.
Info includes with at each char, number of codeunits at each char,
which characters are spaces and wether the text is 'simple' (i.e.
each char has ncodeunits=1) or not.
"""
function get_text_info(text) 
    ctext = collect(text)    
    widths = cumsum(textwidth.(ctext))
    nunits = cumsum(ncodeunits.(ctext))

    issimple = length(text) == ncodeunits(text)
    if issimple
        isspace = ' ' .== ctext
    else
        charidxs = collect(eachindex(text))  # codeunits idx of start of each char
        nchar(unit) = findfirst(charidxs .== prevind(text, unit))  # n chars at codeunit
        isspace = zeros(Bool, length(text))
        isspace[nchar.(findall(' ', text))] .= 1
    end

    return widths, isspace, issimple, nunits
end


"""
    reshape_text(text, width::Int)

Reshape a string to have max width when printed out.

Cut the string into multiple lines so that each line
has at most `width` when printed to terminal: ignoring
ANSI style but taking into account characters with
widths > 1. Text is preferentially split at a space
when possible to improve readability.

Future developer, this function is highly optimized to
reshape text as accurately as possible and as fast as possible.
It took several days to get it to be able to handle 
style information correctly, handle multi codeunit
characters, handle characters with width >1, handle
situations in which the string can't be split up
at a space etc... It's a very delicate balance to get
everything right and changing anything can cause
the whole thing to break, so do so at your peril!
"""
function reshape_text(text, width::Int)
    textwidth(text) <= width && return text

    # Remove style information to simplify reshaping
    text, tags, hasstyle = excise_style(text)

    # extract style information
    original_widths, isspace, issimple, nunits = get_text_info(text)
    widths = view(original_widths, :)

    # infer places where to cut the text
    cuts = [1]
    N = length(original_widths)
    while cuts[end] < ncodeunits(text)
        # start with the worst case: we cut mid-word
        lastcut = cuts[end]
        candidate = findlast(widths .< width)

        if isspace[candidate] == 1
            # we got lucky
            cut = candidate
        else
            # try to get a space in the current line and cut there if possible
            lastspace = findlast(view(isspace, lastcut:candidate)) 
            cut = isnothing(lastspace) ? candidate : lastspace + lastcut
        end

        if cut <= N
            # adjust widths so that we ignore already cut text
            push!(cuts, nunits[cut])
            widths = original_widths .- original_widths[cut]
        else
            # done
            break
        end
    end

    # create output text by slicing up the input text
    out = ""
    applied_cuts::Vector{Int} = []
    for (last, (pre, post)) in loop_last(zip(cuts[1:end-1], cuts[2:end]))
        post - pre <= 1 && continue
        Δ = last ? 0 : 1

        if issimple
            # simple means all characters have 1 codeunit length, easy
            push!(applied_cuts, pre)
            newline = tview(text, pre, post-Δ, :simple)
        else
            # some chars have >1 codeunit length, we need to be careful
            _pre = thisind(text, pre)
            _post = thisind(text, post)
            newline = tview(text, _pre, _post, :simple)
            push!(applied_cuts, _pre)
        end

        # append to output text
        out *= lstrip(newline) * (last ? "" : "\n")
    end

    # if necessary re-insert style information in the reshaped text
    if hasstyle
        return correct_newline_style(reinject_style(out, tags, cuts))
    else
        return out
    end
end
