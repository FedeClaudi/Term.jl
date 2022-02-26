const type_def_regex = [
        r"\:\:+[a-zA-Z0-9.]*",
        r"\{+[a-zA-Z0-9 \,\.. ]*\}",
]

"""
    highlight(text::AbstractString, theme::Theme)

Highlights a text introducing markup to style semantically
relevant segments, colors specified by a theme object
"""
function highlight(text::AbstractString, theme::Theme)
    for regex in type_def_regex
        for match in eachmatch(regex, text)
            text = replace(text, match.match => "[$(theme.type)]$(match.match)[/$(theme.type)]") 
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
    return "[$markup]$(chomp(text))[/$markup]"
end