
# ---------------------------------------------------------------------------- #
#                                     style                                    #
# ---------------------------------------------------------------------------- #

is_mode(string::AbstractString) = string ∈ NAMED_MODES

import Parameters: @with_kw



for test in tests
    println("\e[1;32m"*test*"\e[9;39m")
    tags = []
    while occursin(open_regex, test)
        # get tag declaration
        tag_open = SingleTag(match(open_regex, test))
        println(tag_open)

        # get tag closing
        close_regex = r"\[\/+" * tag_open.markup * r"\]"
        if !occursin(close_regex, test[tag_open.stop:end])
            @warn "Could not find closing tag for $tag_open in $test"
            continue
        end

        tag_close = SingleTag(match(close_regex, test, tag_open.start))
        println(tag_close)

        # get tag
        markup_tag = MarkupTag(tag_open, tag_close)

        # create style from tag
        style = MarkupStyle(markup_tag)
        @info "Style" style

        println(style.color)
        println(style.background)

        # push!(tags, Tag(tag_open, tag_close))
        break
    end

    # has_match = occursin(open_regex, test)
    # if has_match
    #     println(match(open_regex, test))
    # else
    #     println("!!!! TAG OPEN no match for '$test'")
    # end

    # has_match = occursin(tag_close_regex, test)
    # if has_match
    #     println(match(tag_close_regex, test))
    # else
    #     println("!!!! TAG CLOSE no match for '$test'")
    # end
    print("\n")
end
