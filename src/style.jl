module Styles
    include("colors.jl")
    include("modes.jl")
    include("tag.jl")
    include("utils.jl")

    import .Tags: is_tag_closer, TextTag, Tag, tag2ansi

    # ----------------------------------- utils ---------------------------------- #


    """
    Gets the postion of all [ ] and does quality checks.
    """
    function get_brackets_position(text::String)
        starts = find_in_str("[", text)
        ends = find_in_str("]", text)
        nO, nC = length(starts), length(ends)
        
        @assert nO == nC "Unequal number of '[' and ']', case not handled."
        if nO == 0
            return []
        end
    
        for (i, (open, close)) in enumerate(zip(starts, ends))
            # check for nested []
            if i < nO
                if starts[i+1] < close || close < open
                    @debug "Failed to parse text: '$text'" open close starts ends
                    throw("There is a nested set of square brackets or error while parsing text, case not handled")
                end
            end
        end
        return starts, ends, nO, nC
    end
    
    # ---------------------------------------------------------------------------- #
    #                                  Extraction                                  #
    # ---------------------------------------------------------------------------- #
    """
        Extract information about where each Tag is and 
        what paramers it specifies
    """
    function extract_tags(text::String)::Vector{Tag}
        # get [ ] intervals
        starts, ends, nO, nC =  get_brackets_position(text)

        # differentiate not-closing tags / ∉ tag
        openers, closers = [], []
        for (s, e) in zip(starts, ends)
            tag = remove_brackets(text[s:e])
            is_closer = is_tag_closer(tag)
            tag_text = is_closer ? replace(tag, "/"=>"") : tag
            _tag = TextTag(s, e, tag_text, is_closer)
            is_closer ? push!(closers, _tag) : push!(openers, _tag)
        end

        # get open -> close for each tag
        tags = []
        for tag in openers
            closer = [c for c in closers if nospaces(c.text) == nospaces(tag.text) && c.start_char_idx > tag.start_char_idx]
            
            closer_idx = length(closer) > 0 ? closer[1].start_char_idx : -1
            @assert closer_idx > tag.start_char_idx "Did not find a closing tag for $(tag.text), closer: $closer, closers: $([c.text for c in closers])|Text:$text"

            push!(tags, Tag(
                        tag.start_char_idx, 
                        closer[1].end_char_idx , 
                        tag.text, 
                        text[tag.end_char_idx+1:closer[1].start_char_idx-1]
            ))
        end
        return tags
    end

    # ---------------------------------------------------------------------------- #
    #                                   Insertion                                  #
    # ---------------------------------------------------------------------------- #
    """
    Parses out tags from a string and adds style to it.
    """
    function inject_style(text::String)::String
        # get tags from text
        tags = extract_tags(text)
        @debug "Parsing $text, got: " tags
        
        splits = []
        idx = tags[1].start_idx
        if idx > 1
            push!(splits, text[1:idx])
        end
    
        for (i, tag) in enumerate(tags)
            push!(splits, tag2ansi(tag))
            if i < length(tags)
                push!(splits, text[tag.end_idx+1:tags[i+1].start_idx - 1])
            elseif tag.end_idx < length(text)
                push!(splits, text[tag.end_idx+1:end])
            end
        end
        return join(splits)
    end
end