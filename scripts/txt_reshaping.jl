import Term: reshape_text, RenderableText, replace_ansi, ANSI_REGEXEs, get_last_ANSI_code, loop_last, textlen, has_markup, has_ansi
import Term.style: apply_style

struct AnsiTag
    start::Int
    stop::Int
end

# ------------------------------ create reshaped ----------------------------- #
function create_reshaped_text_simple(text, cuts, nunits)
    lines = ""
    for (last, (pre, post)) in loop_last(zip(cuts[1:end-1], cuts[2:end]))
        newline = text[pre:post]
        ansi = get_last_ANSI_code(newline)

        if last
            lines *= lstrip(newline)*"\e[0m"
        else
            lines *= lstrip(newline)*"\e[0m\n"*ansi
        end
    end

    _end = cuts[end] == nunits[end] ? "" : text[cuts[end]:end]
    return lines
end



function create_reshaped_text_complex(text, cuts)
    lines = ""
    for (last, (pre, post)) in loop_last(zip(cuts[1:end-2], cuts[2:end-1]))
        # pre = isvalid(text, pre) ? pre : prevind(text, pre)
        # post = isvalid(text, post) ? post : nextind(text, post)

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

function getcuts_simple(text, width, nunits)
    # get the nunits at each space
    spaces = findall(' ', text) # in n units, not char idx

    # if the text between spaces is too long, add extra spaces
    Δ = 0
    if length(spaces) == 0
        Δ = 1
        spaces = [1, findall(diff(mod.(nunits, width)) .<= 1)[2:end]..., length(text)]
    else
        spaces = [1, spaces..., length(text)]
        extraspaces::Vector{Int} = []

        for (n, δ) in enumerate(diff(spaces))
            if δ > width && n < length(spaces)-1
                # get additional spaces
                s = spaces[n]
                append!(extraspaces,
                    findall(diff(mod.(nunits[s:(s+δ)] .- s, width)) .< 0) .+ (s-1)
                
                )
            end
        end
 
        # add extra spaces and adjust previous spaces values
        # spaces = sort!(vcat(spaces, extraspaces))
        if length(extraspaces) > 1
            for espace in extraspaces
                text = text[1:espace-1] * " " * text[espace:end]
            end
            
            spaces = findall(' ', text)
            _, nunits, _ = get_nunits(text)
        end
    end

    # get the width at each space
    nspaces = length(spaces)
    space_widths = [1, nunits[spaces]..., length(text)]

    # get cuts locations
    addcut(c) = push!(cuts, c)
    cuts::Vector{Int} = [1]
    _space_widths = zeros(Int, length(space_widths))

    _prevsel = 0
    while cuts[end] < textwidth(text) && length(cuts) < length(text)
        if Δ == 0  # there were spaces originally
            _space_widths[:] = space_widths .- nunits[cuts[end]]
            selected = findlast(0 .<= _space_widths .< width)
        else
            _space_widths[:] = space_widths .- nunits[cuts[end]] .+ Δ
            selected = findlast(0 .<= _space_widths .<= width)
        end
        isnothing(selected) && break
        selected = _prevsel == selected ? selected + 1 : selected
        _prevsel = selected

        if selected > nspaces && nspaces > 0
            _candidate = text[cuts[end]:end]
            if textlen(_candidate) > width 
                addcut(spaces[end])
            end
            break
        elseif selected == 1
            break
        else
            addcut(spaces[selected-1])
        end
    end
    addcut(textwidth(text))
 
    return text, cuts, nunits
end

function getcuts_complex(text, width, nunits, widths)
   # get the nunits at each space
   spaces = findall(' ', text) # in n units, not char idx

   # if the text between spaces is too long, add extra spaces
   Δ = 0
   if length(spaces) == 0
       Δ = 1
       spaces = findall(diff(mod.(nunits, width)) .<= 1)[2:end]
   end

   # get the width at each space
   nspaces = length(spaces)
   space_widths = [1, map(s->textwidth(text[1:s]), spaces)..., textwidth(text)]

   # get cuts locations
   addcut(c) = push!(cuts, c)
   cuts::Vector{Int} = [1]

   while cuts[end] < textwidth(text)
        _space_widths = space_widths .- textwidth(text[1:cuts[end]])
        selected = findlast(_space_widths .<= width)
        isnothing(selected) && break

        selected > nspaces && break
        addcut(spaces[selected-1])
   end
   addcut(textwidth(text))

   # cut text
   return cuts
end


# --------------------------------- get nuits -------------------------------- #
function get_nunits(text)
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
        in_tag = ones(Int, length(text))
    end
    widths = cumsum(textwidth.(collect(text)) .*  in_tag)
    return text, nunits, widths
end


# ----------------------------------- main ----------------------------------- #
function test(text, width)
    issimple = length(text) == ncodeunits(text)
    text, nunits, widths = get_nunits(text)
    if issimple
        text, cuts, nunits = getcuts_simple(text, width, nunits)
        return create_reshaped_text_simple(text, cuts, nunits)
    else
        cuts = getcuts_complex(text, width, nunits, widths)
        return create_reshaped_text_complex(text, cuts)
    end
end

text = "my text is very simple it doesn't have any style information"
text = "my text is \e[31mred for a while \e[39mand then it is \e[34malso blue!\e[39m\e[39m"^1
text = "[red]red[/red] and [bold black underline on_green]not[/bold black underline on_green] "^5
# text = "thistexthasaverylongwordfirstandthenashorterone and a short little piece of text"
# text = "thistexth[red]asaverylongw[/red]o[blue]rdfirstandt[/blue]henashorterone and a short little piece of text"

# text = "."^100

# text = "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────"
# text = "나랏말싸미 듕귁에  달아나랏 말싸미 듕귁에 달아 나랏말싸 미 듕귁에 달아 나랏말싸미 듕귁에 달아 나랏말싸미 듕귁에 달아"
# text = "나 랏 말 싸 미 듕 귁 에 달 아 나 랏 말 싸 미 듕 귁 에 나 랏 말 싸 미 듕 귁 에 달 아 나 랏 말 싸 미 듕 귁 에 "

print("\n"^3)
for w in (15, 22)
    println('_'^w)
    # println(t)
    println(test(text, w))
    # print('.'^w)
    @time test(text, w);
    break

end




