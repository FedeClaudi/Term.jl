module markup

    export extract_markup, MarkupTag

    const OPEN_TAG_REGEX = r"\[[a-zA-Z _0-9.,()]+[^/\[]\]"
    const GENERIC_CLOSER_REGEX = r"\[\/\]"

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
            match.offset + length(match.match) - 1,
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

    function extract_markup(input_text::AbstractString)
        text = input_text  # copy so that we can edit it
        tags = []
        for open_match in eachmatch(OPEN_TAG_REGEX, text)
            # get tag declaration
            tag_open = SingleTag(open_match)

            # get tag closing
            close_regex = r"\[\/+" * tag_open.markup * r"\]"
            if !occursin(close_regex, text[tag_open.stop:end])
                # check if a generig closer [/] is present
                if occursin(GENERIC_CLOSER_REGEX, text[tag_open.stop:end])
                    tag_close = SingleTag(match(GENERIC_CLOSER_REGEX, text))
                else
                    # otherwise inject a closer tag at the end
                    text = text * "[/$(tag_open.markup)]"
                    tag_close = SingleTag(match(close_regex, text, tag_open.start))
                end
            else
                tag_close = SingleTag(match(close_regex, text, tag_open.start))
            end

            # crate tag and keep
            push!(tags, MarkupTag(tag_open, tag_close))
        end
        return tags
    end
end