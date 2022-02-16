module text
    include("colors.jl")
    include("modes.jl")
    include("utils.jl")


    import ..renderable
    import ..markup: is_tag_closer, RawSingleTag, Tag, tag2ansi, get_brackets_position, has_tags

    export MarkupText, apply_style, plain

    # ---------------------------------------------------------------------------- #
    #                                     TEXT                                     #
    # ---------------------------------------------------------------------------- #
    struct MarkupText <: renderable.AbstractText
        raw_string::String  # raw user-provided string
        string::String      # formatted string
        tags::Vector{Tag}   # used for debugging/testing
    end

    """
        MarkupText(string)
    Constructs a MarkupText object out of a markup string.
    """
    MarkupText(text::String) = inject_style(text)


    """
    Parses out markup tags from a string and creates a stylized `MarkupText` instance.
    """
    function inject_style(text::AbstractString)::MarkupText
        # get all tags from text
        tags = extract_tags(text)
        
        # substitue each tag with ANSI codes
        parsed = text
        while has_tags(parsed)
            # replace just the first tag
            tag = extract_tags(parsed; first_only=true)

            # handle nested tags
            if has_tags(tag.text)
                nested = inject_style(tag.text).string
                nested = replace(nested, "\e[0m" => "\e[0m[$(tag.definition)]") * "[/$(tag.definition)]"
                tag.text = nested
            end

            # replace tag definition with ANSI escape codes + text
            _start, _end, _ansi = tag.start_idx - 1, tag.end_idx + 1, tag2ansi(tag)

            if tag.start_idx == 1
                parsed = _ansi * parsed[_end:end]
            elseif tag.end_idx == length(text)
                parsed = parsed[1:_start] * _ansi
            else
                parsed = parsed[1:_start] * _ansi * parsed[_end:end]
            end
        end
        
        return MarkupText(text, parsed, tags)
    end

    """
        apply_style(string)

    Applies style to a markup string and returns a string with ASCII codes
    """
    apply_style(string::AbstractString)::AbstractString = inject_style(string).string

    """
        apply_style(strin, style)

    Applies the selected style to a plain string
    """
    apply_style(string::AbstractString, style::Union{Nothing, String}) = isnothing(style) ? string : apply_style("[$style]"*string*"[/$style]")

    apply_style_to_lines(string::AbstractString) = merge_lines([apply_style(ln) for ln in split_lines(string)])

    """
        plain(string::String)
    Removes any style definition from a strin
    """
    plain(string::String) = strip_ansi(apply_style(string))

    plain(text::MarkupText) = strip_ansi(text.string)

    # ---------------------------------------------------------------------------- #
    #                                  Extraction                                  #
    # ---------------------------------------------------------------------------- #
    """
        Extract information about where each Tag is and 
        what paramers it specifies
    """
    function extract_tags(text::AbstractString; first_only=false)  # ::Union{Tag, Vector{Tag}}
        # get [ ] intervals
        starts, ends, nO, nC =  get_brackets_position(text)

        # differentiate not-closing tags / ∉ tag
        openers, closers = [], []
        for (s, e) in zip(starts, ends)
            tag = remove_brackets(text[s:e])
            is_closer = is_tag_closer(tag)
            tag_text = is_closer ? replace(tag, "/"=>"") : tag
            _tag = RawSingleTag(s, e, tag_text, is_closer)
            is_closer ? push!(closers, _tag) : push!(openers, _tag)
        end

        # get open -> close for each tag
        tags = []
        for tag in openers
            # get where the tag closes
            closer = [c for c in closers if nospaces(c.text) == nospaces(tag.text) && c.start_char_idx > tag.start_char_idx]
            closer_idx = length(closer) > 0 ? closer[1].start_char_idx : -1
            if closer_idx <= tag.start_char_idx
                @debug "Failed tag closing" tag closer tag.text text
                @warn("Did not find a closing tag for ''$(tag.text)''")
                continue
            end

            # make sure we get working indices
            start = get_last_valid_str_idx(text, tag.end_char_idx+1)
            stop = get_last_valid_str_idx(text, closer[1].start_char_idx-1)

            try
                push!(tags, Tag(
                            tag.start_char_idx, 
                            closer[1].end_char_idx , 
                            tag.text, 
                            text[start:stop]
                ))
            catch error
                @debug "Failed to create Tag" tag closer text error
                throw("Failed to create tag")
            end

            if first_only
                return tags[1]
            end
        end
        return tags
    end


end