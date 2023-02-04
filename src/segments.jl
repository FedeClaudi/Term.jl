module Segments

import Term: remove_markup, remove_ansi, unescape_brackets

import ..Style: apply_style, MarkupStyle
import ..Measures: Measure, width

using Term: Term

export Segment

# ---------------------------------------------------------------------------- #
#                                    SEGMENT                                   #
# ---------------------------------------------------------------------------- #

"""
    Segment

stores one piece of text with all the styles applied to it.
"""
struct Segment
    text::AbstractString   # text with ANSI codes injected
    measure::Measure       # measure of plain text
end

# ------------------------------- constructors ------------------------------- #
"""
    Segment(text::AbstractString)

Construct a Segment out of a string with markup.
"""
Segment(text) = begin
    text = apply_style(text)
    Segment(text, Measure(text))
end

"""
    Segment(text::Union{Segment, AbstractString}, markup::AbstractString)

Construct a Segment out of a plain string and a markup string with style info
"""
Segment(text, markup::String) = Segment("{$markup}" * text * "{/$markup}")

# --------------------------------- printing --------------------------------- #

Base.show(io::IO, seg::Segment) = print(io, unescape_brackets(seg.text))

Base.show(io::IO, ::MIME"text/plain", seg::Segment) =
    print(io, "Segment{$(typeof(seg.text))} \e[2m(size: $(seg.measure))\e[0m")

# ---------------------------------------------------------------------------- #
#                                    LAYOUT                                    #
# ---------------------------------------------------------------------------- #

# -------------------------------- concatenate ------------------------------- #
"""
concatenate strings and segments
"""
Base.:*(seg::Segment, str::AbstractString) = Segment(seg.text * str)
Base.:*(str::AbstractString, seg::Segment) = Segment(str * seg.text)
Base.:*(seg1::Segment, seg2::Segment) = Segment(seg1.text * seg2.text)

# ------------------------------- string types ------------------------------- #

"""
    get_string_types(segments_vectors...)

Given a number of `Segment[]` vectors, get the `AbstractString` like
type they're using. If they are all using normal `String` or `Substring`
go with that, but if one of them is using a different string type, use it. 
"""
function get_string_types(segments_vectors...)::DataType
    stypes::Vector{DataType} =
        vcat(map(segments -> getfield.(segments, :text), segments_vectors)...) .|>
        typeof |>
        unique

    stypes = setdiff(stypes, [String, SubString])
    return length(stypes) == 0 ? String : stypes[1]
end
end
