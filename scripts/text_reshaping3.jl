import Term: reshape_text, RenderableText, replace_ansi, ANSI_REGEXEs, get_last_ANSI_code, loop_last, textlen, has_markup, has_ansi
import Term.style: apply_style

struct AnsiTag
    start::Int
    stop::Int
end

function get_nunits(text)    
    nchar(unit) = findfirst(charidxs .== unit)  # n chars at codeunit

    if has_markup(text) || has_ansi(text)
        text = apply_style(text)
        charidxs = collect(eachindex(text))  # codeunits idx of start of each char
    
        # get which chars are in a tag and which ones are not
        tags = map(m -> AnsiTag(
                            max(m.offset-1, 1), 
                            nchar(m.offset+textwidth(m.match)-1)
                        ), eachmatch(ANSI_REGEXEs[1], text))

        in_tag = ones(Int, length(text))
        for tag in tags
            in_tag[tag.start:tag.stop] .= 0
        end

        # get a measure of the text width at each char
        nunits = cumsum(ncodeunits.(collect(text)) .*  in_tag)
    else
        charidxs = collect(eachindex(text))  # codeunits idx of start of each char
        nunits = cumsum(ncodeunits.(collect(text)))
        in_tag = ones(Int, length(text))
    end
    
    widths = cumsum(textwidth.(collect(text)) .*  in_tag)
    

    isspace = zeros(Int, length(text))
    isspace[nchar.(findall(' ', text))] .= 1

    issimple = length(text) == ncodeunits(text)
    return text, widths, in_tag, isspace, issimple
end




function test(text, width)
    text, widths, isansi, isspace, issimple = get_nunits(text)
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

        if issimple
            out *= lstrip(text[pre:post-Δ]) * "\n"
        else
            pre = max(prevind(text, pre), 1)
            post = prevind(text, post-Δ)
            out *= lstrip(text[pre:post]) * "\n"
        end
    end
    return out
end

text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
# text = "my text is \e[31mred for a while \e[39mand then it is \e[34malso blue!\e[39m\e[39m"^1
# text = "[red]red[/red] and [bold black underline on_green]not[/bold black underline on_green] "^5
# text = "thistexthasaverylongwordfirstandthenashorterone and a short little piece of text"
# text = "thistexth[red]asaverylongw[/red]o[blue]rdfirstandt[/blue]henashorterone and a short little piece of text"


# text = "استنكار  النشوة وتمجيد الألم نشأت بالفعل، وسأعرض لك"
# text = "لكن لا بد أن أوضح لك أن كل هذه الأفكار المغلوطة حو[/red]ل استنكار  النشوة وتمجيد الألم نشأت بالفعل، وسأعرض لك التفاصيل لتكتشف حقيقة و[red]أساس تلك السعادة"

# text = "น็อคเทค สเก็ตช์แบล็กคอรัปชั่นเบิร์นมอบตัว อาร์พีจีอีสต์แคชเชียร์ รองรับวีเจตุ๊ด แชมป์สกรัมฟอร์มไรเฟิลแทกติค"
# text = "เบอ[red]ร์รีมวลชนต่อรองโฮลวีตว[/red]อลนัท หลวงปู่คอนแทคฟรังก์ แมนชั่[green]นแมกก[/green]าซีนแบ็กโฮออร์แกนฮิ มหาอุปราชาโก๊ะสเตย์เฮีย"

# text = "국가유공자·상이군경 및 전몰군경의 유가족은 법률이 정하는 바에 의하여"
# text = "국[red]가유공자·상이군[bold]경 및 전[/bold]몰군경의 유[/red]가족은 법률이 정하는 바에 의하여"

# text = "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────"
# text = "."^100  # ! not working


print("\n"^3)
for w in (9, 15, 22)
    println('_'^w)
    # println(t)
    println(test(text, w))
    # print('.'^w)
    @time test(text, w)
    # break

end

# TODO get ansi to carry over correctly

# TODO get the end of the text right
# TODO get it to work with other alphabets