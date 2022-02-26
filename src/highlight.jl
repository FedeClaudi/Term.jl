const highlight_regexes = Dict(
    :multiline_code => [ r"\`\`\`[a-zA-Z0-9 \( \) \+ \= \; \. \, \/ \@ \#\s \_ \- \: \!\ \" \> \'\s]*\`\`\`"],
    :code =>[r"\`[a-zA-Z0-9 \( \) \+ \= \; \. \, \/ \@ \#\s \_ \- \: \!\ \" \> \'\s]*\`"], 
    :type => [r"\:\:+[a-zA-Z0-9\.\,]*", r"\{+[a-zA-Z0-9 \,\.. ]*\}"],
)

const code_regex = ""

"""
    highlight(text::AbstractString, theme::Theme)

Highlights a text introducing markup to style semantically
relevant segments, colors specified by a theme object
"""
function highlight(text::AbstractString, theme::Theme)
    for (like, regexes) in highlight_regexes
        markup = getfield(theme, like)

        prev_match = ""
        for regex in regexes
            for match in eachmatch(regex, text)
                # @info "L" length(match.match) match.match like

                # TODO find better way to avoid repeats/mistakes with :code
                if like ==  :code && length(match.match) == 2
                    continue
                end

                if like == :code && match.match == prev_match
                    continue
                end
                prev_match = match.match

                with_markup = do_by_line(x->"[$markup]$x[/$markup]", match.match)
                text = replace(text, match.match => with_markup) 
                # text = replace(text, match.match => "[$markup]$(match.match)[/$markup]") 
            end
        end
    end
    return text
end

"""
    highlight(text::AbstractString, theme::Theme, like::Symbol)

Hilights an entire text as if it was a type of semantically
relevant text of type :like.
"""
function highlight(text::AbstractString, theme::Theme, like::Symbol)
    markup = getfield(theme, like)
    return do_by_line(x->"[$markup]$x[/$markup]", chomp(text))
end