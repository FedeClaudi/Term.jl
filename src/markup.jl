module markup

import Term: replace_double_brackets, OPEN_TAG_REGEX, replace_text
import Term: get_last_valid_str_idx, CLOSE_TAG_REGEX, GENERIC_CLOSER_REGEX

export extract_markup, MarkupTag, pairup_tags, clean_nested_tags, has_markup

# -------------------------------- single tag -------------------------------- #
"""
    SingleTag

Represents a single tag `[style]` or `[/style]`
"""
mutable struct SingleTag
    markup::String
    start::Int
    stop::Int
    isclose::Bool
end

"""
    SingleTag(match::RegexMatch) 

Construct a `SingleTag` out of a `RegexMatch`
"""
function SingleTag(match::RegexMatch)
    _start = match.offset
    _stop = match.offset + length(match.match) - 1

    return SingleTag(match.match[2:(end - 1)], _start, _stop, match.match[2] == '/')
end

# -------------------------------- markup tag -------------------------------- #
"""
    MarkupTag

Represents a complete markup tag.

It stores two `SingleTag`, the text inbetween and any other `MarkupTag`
that was detected in that text.
"""
mutable struct MarkupTag
    markup::String
    open::SingleTag
    close::SingleTag
    text::String
    inner_tags::Vector
end
function MarkupTag(text::AbstractString, open::SingleTag, close::SingleTag, inner::Vector)
    return MarkupTag(open.markup, open, close, text, inner)
end

function Base.show(io::IO, tag::MarkupTag)
    return print(io, "Markup tag ($(length(tag.inner_tags)) inner tags)")
end

# ---------------------------- extract markup tags --------------------------- #

"""
    has_markup(text::String)

Returns `true` if `text` includes a `MarkupTag`
"""
has_markup(text::String) = occursin(OPEN_TAG_REGEX, text)

"""
    extract_markup(input_text::String; firstonly=false)

Extracts `MarkupTag`s from a piece of text.
"""
function extract_markup(input_text::String; firstonly = false)
    text = input_text  # copy so that we can edit it
    tags = []

    while has_markup(input_text)
        # for open_match in eachmatch(OPEN_TAG_REGEX, text)
        open_match = match(OPEN_TAG_REGEX, input_text)

        # get tag declaration
        tag_open = SingleTag(open_match)

        # get tag closing
        close_regex = r"\[\/+" * tag_open.markup * r"\]"
        if !occursin(close_regex, text[(tag_open.stop):end])
            # check if a generig closer [/] is present
            if occursin(GENERIC_CLOSER_REGEX, text[(tag_open.stop):end])
                tag_close = SingleTag(collect(eachmatch(GENERIC_CLOSER_REGEX, text))[end])
            else
                # otherwise inject a closer tag at the end
                text = text * "[/$(tag_open.markup)]"
                input_text = input_text * "[/$(tag_open.markup)]"
                tag_close = SingleTag(match(close_regex, text, tag_open.start))
            end
        else
            tag_close = SingleTag(match(close_regex, text, tag_open.start))
        end

        # crate tag and keep
        _start = tag_open.stop + 1
        _stop = tag_close.start - 1

        _start = !isvalid(text, _start) ? get_next_valid_str_idx(text, _start) : _start
        _stop = !isvalid(text, _stop) ? get_last_valid_str_idx(text, _stop) : _stop
        contained = text[_start:_stop]

        tag_open.stop = _start - 1
        tag_close.start = _stop + 1

        # get nested tags
        inner_tags = extract_markup(input_text[(tag_open.stop + 1):(tag_close.start - 1)])

        # remove tag's inside text
        input_text = replace_text(input_text, tag_open.start - 1, tag_close.stop + 1)

        # @info "TAG" input_text  text contained length(contained)
        push!(tags, MarkupTag(contained, tag_open, tag_close, inner_tags))
        if firstonly
            return tags[1]
        end
    end

    return tags
end

# ----------------------------- helper functions ----------------------------- #

"""
    clean_nested_tags(text::String)::String

Given a text with nested string like:
`[red]aaaa [green]bbbb[/green] cccc [blue] ddddd [/blue]eeee[/red]`

it adds extra tags to ensure that text within inner tags is handled properly, giving:
`[red]aaaa [green]bbbb[/green][red] cccc [/red][blue] ddddd [/blue][red]eeee[/red]`
"""
function clean_nested_tags(text::String)
    if !has_markup(text)
        return text
    end

    # @info "cleaning nested tags" text
    tags = extract_markup(text)
    for tag in tags
        if length(tag.inner_tags) > 0
            text = clean_nested_tags(tag, text)
        end
    end
    # text = join_lines(clean_nested_tags.(, text))
    # @info "after cleaning" text
    return text
end

"""
    clean_nested_tags(tag, text::AbstractString)

recursively applies to inner tags
"""
function clean_nested_tags(tag::MarkupTag, text::AbstractString)
    # @info "     inner cleaning nested tags" text
    for inner in tag.inner_tags
        text = clean_nested_tags(inner, text)

        _tag = "[$(inner.open.markup)]$(inner.text)[$(inner.close.markup)]"
        replacement = "[$(tag.close.markup)]" * _tag * "[$(tag.open.markup)]"
        text = replace(text, _tag => replacement)
    end

    return text
end

"""
    pairup_tags(text::Vector{String})

Given a vector of string with markup tags not properly closed/opened across lines, 
it fixes things up.
"""
function pairup_tags(text::Vector{String})::Vector{String}
    # sweep lines to add tags starts/end
    for i in length(text):-1:1
        # get all open tags
        for opener in reverse(collect(eachmatch(OPEN_TAG_REGEX, text[i])))
            tag_open = SingleTag(opener)

            # get line where it closes
            j = i
            close_regex = r"\[\/+" * tag_open.markup * r"\]"
            for closing_line in text[i:end]
                occursin(close_regex, closing_line) ? break : j += 1
            end

            # if they are in the same line, continue                
            if j == i
                continue
            end

            # if no close tag was found, add it at the end
            if j > length(text)
                text[end] = text[end] * "[/$(tag_open.markup)]"
                j = length(text)
            end

            # add correct close/open markups
            for idx in i:(j - 1)
                text[idx] = text[idx] * "[/$(tag_open.markup)]"
                text[1 + idx] = "[$(tag_open.markup)]" * text[1 + idx]
            end
        end
    end

    # do another sweep to close up orphaned tags
    for (i, line) in enumerate(text)
        for match in eachmatch(CLOSE_TAG_REGEX, line)
            markup = match.match[3:(end - 1)]

            open_regex = r"\[" * markup * r"\]"
            if !occursin(open_regex, line[1:(match.offset)])
                line = "[$markup]" * line
            end
        end
        text[i] = line
    end
    return text
end
end
