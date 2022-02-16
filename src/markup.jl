module markup
    include("__text_utils.jl")
    export extract_markup, MarkupTag



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

    SingleTag(text::AbstractString, match::RegexMatch) = begin  SingleTag(
            match.match[2:end-1],
            get_last_valid_str_idx(text, match.offset),
            get_next_valid_str_idx(text, match.offset + length(match.match) - 1),
            # match.offset,
            # match.offset + length(match.match) - 1,
            match.match[2] == '/'
        )
    end

    # -------------------------------- markup tag -------------------------------- #
    """
        MarkupTag
    
    Represents a complete markup tag.
    """
    mutable struct MarkupTag
        markup::String
        open::SingleTag
        close::SingleTag
        text::String
    end
    MarkupTag(text::AbstractString, open::SingleTag, close::SingleTag) = MarkupTag(open.markup, open, close, text)



    # ---------------------------- extract markup tags --------------------------- #
    has_markup(text::AbstractString) = occursin(OPEN_TAG_REGEX, text)

    function extract_markup(input_text::AbstractString; firstonly=false)
        text = input_text  # copy so that we can edit it
        tags = []
        for open_match in eachmatch(OPEN_TAG_REGEX, text)
            # get tag declaration
            tag_open = SingleTag(text, open_match)

            # get tag closing
            close_regex = r"\[\/+" * tag_open.markup * r"\]"
            if !occursin(close_regex, text[tag_open.stop:end])
                # check if a generig closer [/] is present
                if occursin(GENERIC_CLOSER_REGEX, text[tag_open.stop:end])
                    tag_close = SingleTag(text, match(GENERIC_CLOSER_REGEX, text))
                else
                    # otherwise inject a closer tag at the end
                    text = text * "[/$(tag_open.markup)]"
                    tag_close = SingleTag(text, match(close_regex, text, tag_open.start))
                end
            else
                tag_close = SingleTag(text, match(close_regex, text, tag_open.start))
            end

            # crate tag and keep
            _start = get_last_valid_str_idx(text, tag_open.stop+1)
            _stop = get_next_valid_str_idx(text, tag_close.start-1)
            # _start = tag_open.stop+1
            # _stop = tag_close.start-1
            contained = text[_start:_stop]  # text between tags
            push!(tags, MarkupTag(contained, tag_open, tag_close))
            if firstonly
                return tags[1]
            end
        end
        return tags
    end


end