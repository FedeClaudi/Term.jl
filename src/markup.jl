module markup
    include("__text_utils.jl")
    export extract_markup, MarkupTag, pairup_tags



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

    function SingleTag(text::AbstractString, match::RegexMatch) 
        _start = match.offset
        _stop = match.offset + length(match.match) - 1

        SingleTag(
            match.match[2:end-1],
            _start,
            _stop,
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
        inner_tags::Vector
    end
    MarkupTag(text::AbstractString, open::SingleTag, close::SingleTag, inner::Vector) = MarkupTag(open.markup, open, close, text, inner)

    Base.show(io::IO, tag::MarkupTag) = print(io, "Markup tag ($(length(tag.inner_tags)) inner tags)")


    # ---------------------------- extract markup tags --------------------------- #
    has_markup(text::AbstractString) = occursin(OPEN_TAG_REGEX, text)

    
    function extract_markup(input_text::AbstractString; firstonly=false)
        text = input_text  # copy so that we can edit it
        tags = []

        while has_markup(input_text)
            # for open_match in eachmatch(OPEN_TAG_REGEX, text)
            open_match = match(OPEN_TAG_REGEX, input_text)

            # get tag declaration
            tag_open = SingleTag(text, open_match)

            # get tag closing
            close_regex = r"\[\/+" * tag_open.markup * r"\]"
            if !occursin(close_regex, text[tag_open.stop:end])
                # check if a generig closer [/] is present
                if occursin(GENERIC_CLOSER_REGEX, text[tag_open.stop:end])
                    tag_close = SingleTag(text, collect(eachmatch(GENERIC_CLOSER_REGEX, text))[end])
                else
                    # otherwise inject a closer tag at the end
                    text = text * "[/$(tag_open.markup)]"
                    tag_close = SingleTag(text, match(close_regex, text, tag_open.start))
                end
            else
                tag_close = SingleTag(text, match(close_regex, text, tag_open.start))
            end

            # crate tag and keep
            _start = tag_open.stop+1
            _stop = tag_close.start-1

            _start = !isvalid(text, _start) ? get_next_valid_str_idx(text, _start) : _start
            _stop = !isvalid(text, _stop) ? get_last_valid_str_idx(text, _stop) : _stop
            contained = text[_start:_stop]
            
            tag_open.stop = _start - 1
            tag_close.start = _stop + 1

            # get nested tags
            inner_tags = extract_markup(input_text[tag_open.stop+1:tag_close.start-1])

            # remove tag's inside text
            input_text = replace_text(input_text, tag_open.start-1, tag_close.stop+1)

            push!(tags, MarkupTag(contained, tag_open, tag_close, inner_tags))
            if firstonly
                return tags[1]
            end
        end

        return tags
    end

    # ----------------------------- helper functions ----------------------------- #
    """
        pairup_tags(text::Vector{AbstractString})

    Given a vector of string with markup tags not properly closed/opened across lines, 
    it fixes things up.
    """
    function pairup_tags(text::Vector{AbstractString})::Vector{AbstractString}
        # sweep lines to add tags starts/end
        for i in length(text): -1 : 1
            # get all open tags
            for opener in reverse(collect(eachmatch(OPEN_TAG_REGEX, text[i])))
                tag_open = SingleTag(text[i], opener)

                # get line where it closes
                j = i
                close_regex = r"\[\/+" * tag_open.markup * r"\]"
                for closing_line  in text[i:end]
                    occursin(close_regex, closing_line) ? break : j += 1
                end
                
                if j == i
                    continue
                end
                # @info "Got tag start end" tag_open.markup i j 

                # add correct close/open markups
                for idx in i:(j-1)
                    text[idx] = text[idx] * "[/$(tag_open.markup)]"
                    text[1 + idx] = "[$(tag_open.markup)]" * text[1 + idx]
                end


            end
        end

        # do another sweep to close up orphaned tags
        for (i, line) in enumerate(text)
            for match in eachmatch(CLOSE_TAG_REGEX, line)
                markup = match.match[3:end-1]

                open_regex = r"\[" * markup * r"\]"
                if !occursin(open_regex, line[1:match.offset])
                    
                    line = "[$markup]" * line
                    # @info "injected" markup i line
                end
                
            end
            text[i] = line
        end
        return text
    end
end