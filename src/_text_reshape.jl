import Base: rpad as brpad

"""
    reshape_text(text::AbstractString, width::Int)

Reshape a text to have a given width. 

Insert newline characters in a string so that each line is within the given width.
"""
function reshape_text(text::AbstractString, width::Int; ignore_markup::Bool = false)
    occursin('\n', text) && (
        return do_by_line(
            ln -> reshape_text(ln, width::Int; ignore_markup = ignore_markup),
            text,
        )
    )
    textlen(text) ≤ width && return text

    lines = []
    line, line_length = "", 0
    bracketed = false
    in_escape_code = false
    for c in text
        # check if we are entering a special context
        if c == '\e'
            in_escape_code = true
        end
        if c == '{' && !ignore_markup
            bracketed = true
        end

        line *= c

        # see if we need to go to a new line
        if !bracketed && !in_escape_code
            line_length += textwidth(c)

            if line_length + 1 > width
                push!(lines, rstrip(line))
                line, line_length = "", 0
            elseif (line_length + 1 > width - 5) && (c == ' ')
                push!(lines, rstrip(line))
                line, line_length = "", 0
            end
        end

        # check if we are exiting from a special context
        if c == 'm' && in_escape_code
            in_escape_code = false
        end
        if c == '}'
            bracketed = false
        end
    end
    push!(lines, rstrip(line))

    out = join((fix_ansi_across_lines ∘ fix_markup_across_lines)(lines), "\n")
    chomp(out)
end

"""
    justify(text::AbstractString, width::Int)::String

Justify a piece of text spreading out text to fill in a given width.
"""
function justify(text::AbstractString, width::Int)::String
    returnfn(text) = text * ' '^(width - textlen(text))

    occursin('\n', text) && (return do_by_line(ln -> justify(ln, width), text))

    # cleanup text
    text = strip(text)
    text = endswith(text, "\e[0m") ? text[1:(end - 4)] : text
    text = strip(text)
    n_spaces = width - textlen(text)
    (n_spaces < 2 || textlen(text) ≤ 0.5width) && (return returnfn(text))

    # get number of ' ' and their location in the string
    spaces_locs = map(m -> m[1], findall(" ", text))
    spaces_locs = length(spaces_locs) < 2 ? spaces_locs : spaces_locs[1:(end - 1)]
    n_locs = length(spaces_locs)
    n_locs < 1 && (return returnfn(text))
    space_per_loc = div(n_spaces, n_locs)
    space_per_loc == 0 && (return returnfn(text))

    inserted = 0
    for (last, loc) in loop_last(spaces_locs)
        n_to_insert = last ? width - textlen(text) : space_per_loc
        to_insert = " "^n_to_insert
        text = replace_text(text, loc + inserted, loc + inserted, to_insert)
        inserted += n_to_insert
    end
    return returnfn(text)
end

"""
    text_to_width(text::AbstractString, width::Int)::String

Cast a text to have a given width by reshaping, it and padding.
It includes an option to justify the text (:left, :right, :center, :justify).
"""
function text_to_width(
    text::AbstractString,
    width::Int,
    justify::Symbol;
    background::Union{String,Nothing} = nothing,
)::String
    # reshape text
    if Measure(text).w > width
        text = reshape_text(text, width - 1)
    end
    return pad(text, width, justify, bg = background)
end
