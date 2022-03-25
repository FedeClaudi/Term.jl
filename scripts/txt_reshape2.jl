import Term: reshape_text, RenderableText, replace_ansi, ANSI_REGEXEs, get_last_ANSI_code, loop_last, textlen, has_markup, has_ansi
import Term.style: apply_style

struct AnsiTag
    start::Int
    stop::Int
end

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
    
    isspace = zeros(Int, length(text))
    @info findall(' ', text) "spaces units"
    @info prevind.(text, findall(' ', text), 1)
    @info nunits
    isspace[] .= 1
    return text, widths, in_tag, isspace
end




function test(text, width)
    text, widths, isansi, isspace = get_nunits(text)
    original_widths = widths

    # get yhe last char within width
    cuts = [1]
    N = length(original_widths)
    while cuts[end] <= N
        candidate = findlast(widths .<= width)
        if isnothing(candidate)
            @info cuts text[cuts[end]:end]
        end

        if isspace[candidate] == 1
            cut = candidate
        else
            # get the last valid space
            lastspace = findlast(isspace[cuts[end]:candidate] .== 1) 

            if isnothing(lastspace)
                # no valid space
                newcandidate = findlast(isansi[cuts[end]:candidate] .!= 1)
                if isnothing(newcandidate)
                    cut = cuts[end]+width
                else
                    cut = newcandidate + cuts[end]
                end
            else
                cut = lastspace+ cuts[end]
            end
        end
        cut == cuts[end] && break

        # @info widths cut candidate
        if cut < N
            push!(cuts, cut)
            widths = original_widths .- sum(original_widths[cut])
        else
            push!(cuts, ncodeunits(text))
            break
        end
    end
    

    out = ""
    for (last, (pre, post)) in loop_last(zip(cuts[1:end-1], cuts[2:end]))
        Δ = last ? 0 : 1
        out *= lstrip(text[pre:post-Δ]) * "\n"
    end
    return out
end

text = "my text is very simple it doesn't have any style information"
text = "my text is \e[31mred for a while \e[39mand then it is \e[34malso blue!\e[39m\e[39m"^1
text = "[red]red[/red] and [bold black underline on_green]not[/bold black underline on_green] "^5
text = "thistexthasaverylongwordfirstandthenashorterone and a short little piece of text"
text = "thistexth[red]asaverylongw[/red]o[blue]rdfirstandt[/blue]henashorterone and a short little piece of text"

text = "."^100  # ! not working

# text = "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────"
# text = "나랏말싸미 듕귁에  달아나랏 말싸미 듕귁에 달아 나랏말싸 미 듕귁에 달아 나랏말싸미 듕귁에 달아 나랏말싸미 듕귁에 달아"
text = "나 랏 말 싸 미 듕 귁 에 달 아 나 랏 말 싸 미 듕 귁 에 나 랏 말 싸 미 듕 귁 에 달 아 나 랏 말 싸 미 듕 귁 에 "

print("\n"^3)
for w in (9, 15, 22)
    println('_'^w)
    # println(t)
    println(test(text, w))
    # print('.'^w)
    @time test(text, w)
    break

end

# TODO make sure chars are not repeated
# TODO get the right place to stop the cut extraction loop_last
# TODO make it work in all case
# TODO get lorem ipsum in other alphabets.