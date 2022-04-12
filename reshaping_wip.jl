

function test(text, width)
    totwidth = textwidth(text)
    chars = collect(text)
    widths = textwidth.(chars)
    cumwidths = cumsum(widths)

    nlines = Int(floor(totwidth / width)) + 1
    idx = 1
    linebreaks = []
    for n in 1:nlines
        # get char at max width
        candidate = findfirst(cumwidths .- cumwidths[idx] .> width)
        isnothing(candidate) && break

        # get last space
        for i in 1:5
            chars[candidate - i - n] == ' ' && begin
                candidate = candidate - i
                break
            end
        end

        # adjust idx/candidate
        if idx == 1
            candidate -= 1
            idx = candidate
        else
            # candidate -= 1
            idx += candidate - linebreaks[end]
        end
 
        push!(linebreaks, candidate)
        idx > length(chars) && break
    end


    # add line breaks
    map(idx -> insert!(chars, idx, '\n'), linebreaks)

    println(
        replace(join(chars), "\n "=>"\n")
    )
    nothing
end


# TODO get it to work with style

# text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
text = "국가유공자·상이군경 및 전몰군경의 유가족은 법률이 정하는 바에의하여"
# text = "┌────────────────┬────────────────┬────────────────┬────────────────┬"

width = 33

print("\n"^2)

println(text)
println("_"^width)
test(text, width)

println("_"^width)

# @time test(text, width)
# @time test(text, width)
