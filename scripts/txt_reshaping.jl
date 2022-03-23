import Term: reshape_text, RenderableText, replace_ansi, ANSI_REGEXEs, get_last_ANSI_code, loop_last, textlen, has_markup, has_ansi
import Term.style: apply_style

struct AnsiTag
    start::Int
    stop::Int
end

# ------------------------------ create reshaped ----------------------------- #
function create_reshaped_text_simple(text, cuts)
    lines = ""
    for (last, (pre, post)) in loop_last(zip(cuts[1:end-2], cuts[2:end-1]))
        newline = text[pre:post]
        ansi = get_last_ANSI_code(newline)

        if last
            lines *= lstrip(newline)*"\e[0m"
        else
            lines *= lstrip(newline)*"\e[0m\n"*ansi
        end
    end
    return chomp(lines)
end



function create_reshaped_text_complex(text, cuts)
    lines = ""
    for (last, (pre, post)) in loop_last(zip(cuts[1:end-2], cuts[2:end-1]))
        pre = isvalid(text, pre) ? pre : prevind(text, pre)
        post = isvalid(text, post) ? post : nextind(text, post)

        newline = text[pre:post]
        ansi = get_last_ANSI_code(newline)

        if last
            lines *= lstrip(newline)*"\e[0m"
        else
            lines *= lstrip(newline)*"\e[0m\n"*ansi
        end
    end
    return chomp(lines)
end





# --------------------------------- get cuts --------------------------------- #

# function getcuts_simple_nospaces(text, width, nunits, widths)
#     spaces = 
# end

function getcuts_simple(text, width, nunits)
    # !occursin(' ', text) && return getcuts_simple_nospaces(text, width, nunits, widths)

    # get the nunits at each space
    spaces = findall(' ', text) # in n units, not char idxcc

    # if the text between spaces is too long, add extra spaces
    Δ = 0
    if length(spaces) == 0
        Δ = 1
        spaces = findall(diff(mod.(nunits, width)) .<= 1)[2:end]
    end

    # get the width at each space
    nspaces = length(spaces)
    space_widths = [1, nunits[spaces]..., length(text)]

    # get cuts locations
    addcut(c) = push!(cuts, c)
    cuts::Vector{Int} = [1]
    _space_widths = zeros(Int, length(space_widths))

    while cuts[end] < textwidth(text)
        if Δ == 0  # there were spaces originally
            _space_widths[:] = space_widths .- nunits[cuts[end]]
            selected = findlast(0 .<= _space_widths .< width)
        else
            _space_widths[:] = space_widths .- nunits[cuts[end]] .+ Δ
            selected = findlast(0 .<= _space_widths .<= width)
        end
        isnothing(selected) && break

        if selected > nspaces && nspaces > 0
            _candidate = text[cuts[end]:end]
            if textlen(_candidate) > width 
                addcut(spaces[end])
            end
            break
        elseif selected == 1
            # @info space_widths cuts selected 
            break
        else
            addcut(spaces[selected-1])
        end
    end
    addcut(textwidth(text))
 
    # cut text
    return cuts
end


function test(text, width)
    issimple = length(text) == ncodeunits(text)

    if has_markup(text) || has_ansi(text)
        text = apply_style(text)

        # get which chars are in a tag and which ones are not
        tags = map(m -> AnsiTag(
                            max(m.offset-1, 1), 
                            m.offset+textwidth(m.match)-1
                        ), eachmatch(ANSI_REGEXEs[1], text))

        in_tag = ones(Int, length(text))
        for tag in tags
            in_tag[tag.start:tag.stop] .= 0
        end

        # get a measure of the text width at each char
        nunits = cumsum(ncodeunits.(collect(text)) .*  in_tag)
    else
        nunits = cumsum(ncodeunits.(collect(text)))
    end

    if issimple
        cuts = getcuts_simple(text, width, nunits)
        return create_reshaped_text_simple(text, cuts)
    else
        widths = cumsum(textwidth.(collect(text)) .*  in_tag)
        cuts = getcuts_simple(text, width, nunits, widths)
    end
end

text = "my text is very simple it doesn't have any style information"
# text = "my text is \e[31mred for a while \e[39mand then it is \e[34malso blue!\e[39m\e[39m"^1
# text = "[red]red[/red] and [bold black underline on_green]not[/bold black underline on_green] "^5
# text = "."^100

# text = "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────"
# text = "나랏말싸미 듕귁에  달아나랏 말싸미 듕귁에 달아 나랏말싸 미 듕귁에 달아 나랏말싸미 듕귁에 달아 나랏말싸미 듕귁에 달아"
# text = "나 랏 말 싸 미 듕 귁 에 달 아 나 랏 말 싸 미 듕 귁 에 나 랏 말 싸 미 듕 귁 에 달 아 나 랏 말 싸 미 듕 귁 에 "

print("\n"^3)
for w in (9, 15, 22)
    println('_'^w)
    # println(t)
    @time println(test(text, w))
    # print('.'^w)
    # @time test(text, w)

end





# text = apply_style(text)

# # get which chars are in a tag and which ones are not
# tags = map(m -> AnsiTag(
#                     max(m.offset-1, 1), 
#                     m.offset+textwidth(m.match)-1
#                 ), eachmatch(ANSI_REGEXEs[1], text))

# in_tag = ones(Int, length(text))
# for tag in tags
#     in_tag[tag.start:tag.stop] .= 0
# end

# # get a measure of the text width at each char
# nunits = cumsum(ncodeunits.(collect(text)) .*  in_tag)
# widths = cumsum(textwidth.(collect(text)) .*  in_tag)
# idxs = cumsum(length.(collect(text)) .*  in_tag)  # idx of each valid char

# # get the nunits at each space
# spaces = findall(' ', text) # in n units, not char idxcc

# # if the text between spaces is too long, add extra spaces
# Δ = 0
# if length(spaces) == 0
#     Δ = -1
#     spaces = findall(diff(mod.(widths, width)) .<= 1)[2:end]
# end

# # get the width at each space
# nspaces = length(spaces)
# swidth(space) = widths[length(text[1:space])]  # get the width of the text up to the space
# sidx(space) = idxs[length(text[1:space])]
# space_widths = [1, swidth.(spaces)..., textwidth(text)]

# # get cuts locations
# addcut(c) = push!(cuts, c)
# cuts::Vector{Int} = [1]
# _space_widths = zeros(Int, length(space_widths))
# while cuts[end] < textwidth(text)
#     _space_widths[:] = space_widths .- nunits[cuts[end]] .- Δ
#     selected = findlast(0 .<= _space_widths .<= width)

#     if isnothing(selected) 
#         break
#     end

#     if selected > nspaces
#         _cut = max(nextind(text, cuts[end]), 1)
#         _candidate = text[_cut:end]
#         if textlen(_candidate) > width && nspaces > 0
#             addcut(spaces[end])
#             addcut(textwidth(text))
#         else
#             addcut(textwidth(text))
#         end
#         break
#     else
#         addcut(spaces[selected-1])
#     end
# end
# addcut(textwidth(text))

# # cut text
# return create_reshaped_text(text, cuts)