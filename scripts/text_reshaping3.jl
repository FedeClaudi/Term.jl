import Term: reshape_text, RenderableText, replace_ansi, ANSI_REGEXE, get_ANSI_codes, loop_last, textlen, has_ansi, tview
import Term.style: apply_style

struct AnsiTag
    start::Int
    stop::Int
end

function get_text_info(text) 
    text = apply_style(text)
    ctext = collect(text)
    charidxs = collect(eachindex(text))  # codeunits idx of start of each char
    
    notansi = ones(Int, length(text))

    nchar(unit) = findfirst(charidxs .== prevind(text, unit))  # n chars at codeunit

    if has_ansi(text)
        hasstyle = true
   
        # get which chars are in a tag and which ones are not
        tags = map(m -> AnsiTag(
                            max(m.offset-1, 1), 
                            nchar(m.offset+textwidth(m.match)-1)
                        ), eachmatch(ANSI_REGEXE, text))

        for tag in tags
            notansi[tag.start:tag.stop] .= 0
        end
    else
        hasstyle = false
    end
    
    widths = cumsum(textwidth.(ctext) .*  notansi)
    nunits = cumsum(ncodeunits.(ctext))

    isspace = zeros(Bool, length(text))
    isspace[nchar.(findall(' ', text))] .= 1

    issimple = length(text) == ncodeunits(text)
    return text, widths, notansi, isspace, issimple, hasstyle, nunits, nchar
end




function test(text, width)
    text, original_widths, notansi, isspace, issimple, hasstyle, nunits, nchar = get_text_info(text)
    widths = view(original_widths, :)

    # get yhe last char within width
    cuts = [1]
    N = length(original_widths)
    while cuts[end] < ncodeunits(text)
        lastcut = cuts[end]
        candidate = findlast(widths .< width)
        if isnothing(candidate)
            @info cuts text[lastcut:end]
            break
        end

        if isspace[candidate] == 1
            cut = candidate
        else
            # get the last valid space
            lastspace = findlast(view(isspace, lastcut:candidate)) 
            # lastspace = findlast(' ', tview(text, 1, candidate))

            if isnothing(lastspace)
                cut = candidate
                # @info candidate notansi[candidate] lastcut nchar(lastcut) notansi[candidate-3:candidate] 
                
                # ÷findlast(view(notansi, nchar(lastcut):candidate) == 1)
                # cut = findlast(view(notansi, nchar(lastcut):nchar(candidate)) == true)
                # # no valid space, get last non-ansi char
                # newcandidate = findlast(view(notansi, lastcut:candidate))
                # if isnothing(newcandidate)
                #     cut = candidate #
                #     # cut = min(lastcut+width, ncodeunits(text))
                # else
                #     # cut = newcandidate + lastcut + 1
                #     cut = candidate
                # end
            else
                cut = lastspace + lastcut
            end
        end
        if cut == lastcut
            @warn "stopping because cut is repeated" cut
            break
        end
        # cut == lastcut && break

        if cut <= N
            push!(cuts, nunits[cut])
            widths = original_widths .- original_widths[cut]
        else
            @warn widths cut text[cut:end] length(original_widths) length(text)
            break
        end
    end

    # @info cuts
    out = ""
    for (last, (pre, post)) in loop_last(zip(cuts[1:end-1], cuts[2:end]))
        post - pre <= 1 && continue
        Δ = last ? 0 : 1

        if issimple
            newline = tview(text, pre, post-Δ, :simple)
        else
            # @info "prepost" pre post thisind(text, pre) thisind(text, post) text[1:thisind(text, post+1)]
            _pre = thisind(text, pre)
            _post = thisind(text, post)
            newline = tview(text, _pre, _post, :simple)
        end

        ansi = hasstyle ? get_ANSI_codes(newline) : ""
        # @info "newline" newline ansi
        if last
            out *= lstrip(newline)*"\e[0m"
        else
            out *= lstrip(newline)*"\e[0m\n"*ansi
        end
    end
    return out
end

function getlast_notansi(idx, notansi)
    # @info "idx" idx
    _idx = findlast(notansi[1:idx])
    return isnothing(_idx) ? idx : idx
end

text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
# text = "Lorem [red]ipsum dolor sit [underline]amet, consectetur[/underline] adipiscing elit, [/red][blue]sed do eiusmod tempor incididunt[/blue] ut labore et dolore magna aliqua."
# text = "Lorem[red]ipsumdolorsit[underline]amet, consectetur[/underline] adipiscing elit, [/red]seddoeiusmo[blue]dtemporincididunt[/blue]ut labore et dolore magna aliqua."


# text = "استنكار  النشوة وتمجيد الألم نشأت بالفعل، وسأعرض لك"
# text = "لكن لا بد أن أوضح لك أن كل هذه الأفكار المغلوطة حو[/red]ل استنكار  النشوة وتمجيد الألم نشأت بالفعل، وسأعرض لك التفاصيل لتكتشف حقيقة و[red]أساس تلك السعادة"

# text = "ต้าอ่วยวาทกรรมอาว์เซี้ยว กระดี๊กระด๊า ช็อปซาดิสต์โมจิดีพาร์ตเมนต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน "
# text = "ต้าอ่วยวาท[red]กรรมอาว์เซี้ยว กระดี๊กระด๊า [/red]ช็อปซาดิสต์โมจิดีพาร์ตเม[blue underline]นต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเต[/blue underline]อร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน "

# text = "국가유공자·상이군경 및 전몰군경의 유가족은 법률이 정하는 바에 의하여"
# text = "국[red]가유공자·상이군[bold]경 및 전[/bold]몰군경의 유[/red]가족은 법률이 정하는 바에 의하여"

# text = "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────"
# text = "┌──────────[red]────[/red]──┬[blue bold]────────────────┬──[/blue bold]──────────────┬────────────────┬──────────────end"

# text = "."^100  
# text = ".[red]...[/red]...."^10

print("\n"^3)
for w in (15, 22, 46)
    println('_'^w)
    # println(t)
    println(test(text, w))
    # print('.'^w)
    @time test(text, w)
    break

end

# TODO figure out why third text breaks things
# TODO get it to work with other alphabets