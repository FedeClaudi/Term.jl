import Term: textlen, apply_style, OPEN_TAG_REGEX, do_by_line

rx = r"\s*\S+\s*"

function words(text)
    return map(
        m -> (m.offset, m.offset + textlen(m.match), m.match, textlen(m.match)),
        eachmatch(rx, text),
    )
end

function characters(word)
    chars = collect(word)
    widths = textwidth.(chars)
    return map(i -> (chars[i], widths[i]), 1:length(chars))
end

function style_at_each_line(text)
    lines = split(text, "\n")
    for (i, line) in enumerate(lines)
        for tag in eachmatch(OPEN_TAG_REGEX, line)
            markup = tag.match[2:(end - 1)]
            close_rx = r"(?<!\{)\{(?!\{)\/" * markup * r"\}"
            close_tag = match(close_rx, text)

            if isnothing(close_tag) && i < length(lines)
                lines[i + 1] = "{$markup}" * lines[i + 1]
            end
        end
    end
    return join(lines, "\n")
end

function split_tags_into_words(text)
    tags = map(m -> m.match[2:(end - 1)], eachmatch(OPEN_TAG_REGEX, text))

    for markup in tags
        tag = match(Regex("\\{$markup\\}"), text)
        if isnothing(tag)
            continue
        end

        close_rx = r"(?<!\{)\{(?!\{)\/" * markup * r"\}"
        close_tag = match(close_rx, text)

        if isnothing(close_tag)
            continue
        end

        tag_words = map(
            w -> replace(replace(w, "{" => ""), "}" => ""),
            ([w[3] for w in words(tag.match)]),
        )
        if length(tag_words) > 1
            openers = join(map(w -> "{" * rstrip(w) * "}", tag_words))
            closers = join(map(w -> "{/" * rstrip(w) * "}", tag_words))

            try
                text =
                    text[1:(tag.offset - 1)] *
                    openers *
                    text[(tag.offset + textwidth(markup) + 2):(close_tag.offset - 1)] *
                    closers *
                    text[(close_tag.offset + textwidth(markup) + 3):end]
            catch
                text =
                    text[1:prevind(text, tag.offset - 1)] *
                    openers *
                    text[nextind(text, tag.offset + textwidth(markup) + 2):prevind(
                        text,
                        close_tag.offset - 1,
                    )] *
                    closers *
                    text[prevind(text, close_tag.offset + textwidth(markup) + 3):end]
            end
        end
    end
    return text
end

"""
    reshape_text(text::AbstractString, width::Int)

Reshape a text to have a given width. 

Insert newline characters in a string so that each line is within the given width.
"""
function reshape_text(text::AbstractString, width::Int)
    # if occursin('\n', text)
    #     return do_by_line(ln -> reshape_text(ln, width), text)
    # end

    text = split_tags_into_words(text)
    position = 0
    cuts = []
    for (start, stop, word, word_length) in words(text)
        if position + word_length >= width
            # we need to cut the text
            if word_length > width
                # the word is longer than the line
                word_chars = characters(word)
                I = length(text[1:start]) + length(cuts)
                position > 0 && push!(cuts, I)
                position = word_chars[1][2]  # width of first char

                for (i, (char, w)) in enumerate(word_chars[2:end])
                    if position + w > width
                        push!(cuts, I + i)
                        position = w
                    else
                        position += w
                    end
                end

                if position + word_chars[end][2] >= width
                    push!(cuts, I + length(word_chars) - 1)
                end

            elseif position > 0 && start > 1
                push!(cuts, length(text[1:start]) + length(cuts))
                position = word_length
            end
        else
            position += word_length
        end
    end

    chars = collect(text)
    for cut in cuts
        insert!(chars, cut, '\n')
    end
    apply_style(style_at_each_line(join(chars)))
end
