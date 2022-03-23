import Term: reshape_text, RenderableText, replace_ansi, ANSI_REGEXEs, get_last_ANSI_code, loop_last, textlen


struct AnsiTag
    start::Int
    stop::Int
end


function get_putative_cuts(text, width)
    # get which chars are in a tag and which ones are not
    tags = map(m -> AnsiTag(
                        m.offset-1, 
                        m.offset+textwidth(m.match)-1
                    ), eachmatch(ANSI_REGEXEs[1], text))

    in_tag = ones(Int, length(text))
    for tag in tags
        in_tag[tag.start:tag.stop] .= 0
    end

    # get a measure of the text width at each char
    nunits = cumsum(ncodeunits.(collect(text)) .*  in_tag)

    return findall(diff(mod.(nunits, width)) .< 0)
end


function test(width)
    text = "my text is \e[31mred for a while \e[39mand then it is \e[34malso blue!\e[39m\e[39m"^1



    # get which chars are in a tag and which ones are not
    tags = map(m -> AnsiTag(
                        m.offset-1, 
                        m.offset+textwidth(m.match)-1
                    ), eachmatch(ANSI_REGEXEs[1], text))

    in_tag = ones(Int, length(text))
    for tag in tags
        in_tag[tag.start:tag.stop] .= 0
    end

    # get a measure of the text width at each char
    nunits = cumsum(ncodeunits.(collect(text)) .*  in_tag)

    # get the nunits at each space
    spaces = findall(' ', text)
    nspaces = length(spaces)
    space_widths = [1, nunits[spaces]..., textwidth(text)]

    # get cuts at spaces
    cuts::Vector{Int} = [1]
    _space_widths = zeros(Int, length(space_widths))
    while cuts[end] < textwidth(text)
        _space_widths[:] = space_widths .- nunits[cuts[end]]
        selected = findlast(0 .<= _space_widths .< width)
        isnothing(selected) && break

        if selected > nspaces
            _candidate = text[cuts[end]:end]
            if textlen(_candidate) > width
                push!(cuts, spaces[end])
                push!(cuts, textwidth(text))
            else
                push!(cuts, textwidth(text))
            end
            break
        else
            push!(cuts, spaces[selected-1])
        end
    end
    push!(cuts, textwidth(text))
 
    # cut text
    lines = ""
    for (last, (pre, post)) in loop_last(zip(cuts[1:end-1], cuts[2:end]))
        newline = text[pre:post-1]
        ansi = get_last_ANSI_code(newline)

        if last
            lines *= lstrip(newline)*"\e[0m"
        else
            lines *= lstrip(newline)*"\e[0m\n"*ansi
        end
    end
    return chomp(lines)
end

print("\n"^3)
for w in (10, 15, 22)
    println('_'^w)
    # println(t)
    # println(test(w))
    # print('.'^w)
    @time test(w)

end


# text = "my text is [red]red for a while [/red]and then it is [blue]also blue![/blue] "

# # for w in (10, 14, 19, 28, 36, 41, 60)
# #     println("."^w)
# #     println(reshape_text(text, w))
# # end


# # TODO look at RenderableText
# tt = text^5

# for w in (10, 14, 19, 28, 36, 41, 60)
#     println("."^w)
#     println(RenderableText(tt; width=w))
#     @time RenderableText(tt; width=w)
# end