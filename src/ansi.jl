module ansi

    export extract_markup, MarkupTag

    const OPEN_TAG_REGEX = r"\[[a-zA-Z _]+[^/]\]"

    # -------------------------------- single tag -------------------------------- #
    """
        SingleTag

    Represents a single tag `[style]` or `[/style]`
    """
    struct SingleTag
        markup::String
        start::Int
        stop::Int
        isclose::Bool
    end

    SingleTag(match::RegexMatch) = begin  SingleTag(
            match.match[2:end-1],
            match.offset,
            match.offset + length(match.match),
            match.match[2] == '/'
        )
    end

    # -------------------------------- markup tag -------------------------------- #
    """
        MarkupTag
    
    Represents a complete markup tag.
    """
    struct MarkupTag
        markup::String
        open::SingleTag
        close::SingleTag
    end
    MarkupTag(open::SingleTag, close::SingleTag) = MarkupTag(open.markup, open, close)



    # ---------------------------- extract markup tags --------------------------- #
    """
        erase_tag

    Replace the portion of the text corresponding to a SingleTag with '_'
    """
    function erase_tag(tag::SingleTag, text::AbstractString)
        blank = "_"^(length(tag.markup)+2)
        if tag.start == 1
            censored = blank * " " * text[tag.stop+1:end]
        elseif tag.stop == length(text)
            censored = text[1:tag.start-1] * blank
        else
            censored = text[1:tag.start-1] * blank * text[tag.stop+1:end]
        end

        @assert length(censored) == length(text) "Something whent wrong with erase tag, was $(length(text)) is $(length(censored))\ntag: $tag -  blank: '$blank'\nnew text: $censored"
        return censored
    end

    function extract_markup(input_text::AbstractString)
        text = input_text  # copy so that we can edit it
        tags = []
        while occursin(OPEN_TAG_REGEX, text)
            # get tag declaration
            tag_open = SingleTag(match(OPEN_TAG_REGEX, text))

            # get tag closing
            close_regex = r"\[\/+" * tag_open.markup * r"\]"
            if !occursin(close_regex, text[tag_open.stop:end])
                @warn "Could not find closing tag for $tag_open in $text"
                continue
            end

            tag_close = SingleTag(match(close_regex, text, tag_open.start))

            # remove tag from text to avoid re-detecting it
            text = erase_tag(tag_close, erase_tag(tag_open, text))

            # crate tag and keep
            push!(tags, MarkupTag(tag_open, tag_close))
        end
    end
end