module Segments

import Term: remove_markup, remove_ansi, unescape_brackets

import ..Style: apply_style, MarkupStyle
import ..Measures: Measure

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
    text::String   # text with ANSI codes injected
    measure::Measure       # measure of plain text
end

# ------------------------------- constructors ------------------------------- #
"""
    Segment(text::AbstractString)

Construct a Segment out of a string with markup.
"""
Segment(text) = Segment(apply_style(text), Measure(text))

"""
    Segment(text::Union{Segment, AbstractString}, markup::AbstractString)

Construct a Segment out of a plain string and a markup string with style info
"""
Segment(text, markup::String) = Segment("{$markup}" * text * "{/$markup}")

Segment(seg::Segment) = seg

# --------------------------------- printing --------------------------------- #

Base.show(io::IO, seg::Segment) = print(io, unescape_brackets(seg.text))

Base.show(io::IO, ::MIME"text/plain", seg::Segment) =
    print(io, "Segment \e[2m(size: $(seg.measure))\e[0m")

# ---------------------------------------------------------------------------- #
#                                    LAYOUT                                    #
# ---------------------------------------------------------------------------- #

"""
    Term.fillin(segments::Vector{Segment})::Vector{Segment}

Ensure that for each segment the text has the same width
"""
function Term.fillin(segments::Vector{Segment})::Vector{Segment}
    widths = [seg.measure.w for seg in segments]
    w = max(widths...)

    filled::Vector{Segment} = []
    for seg in segments
        push!(filled, Segment(seg.text * " "^(w - seg.measure.w)))
    end
    return filled
end

# -------------------------------- concatenate ------------------------------- #
"""
concatenate strings and segments
"""
Base.:*(seg::Segment, str::AbstractString) = Segment(seg.text * str)
Base.:*(str::AbstractString, seg::Segment) = Segment(str * seg.text)
Base.:*(seg1::Segment, seg2::Segment) = Segment(seg1.text * seg2.text)

end
