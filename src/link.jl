module Links
import ..Measures: Measure, width
import ..Measures
import ..Segments
import ..Segments: Segment
import ..Style: apply_style
import ..Renderables: RenderableText, AbstractRenderable
import ..Renderables
import ..Layout: pad
import Term: textlen, TERM_THEME, cleantext, excise_link_display_text, remove_ansi
import Term

export Link

"""
    struct LinkString <: AbstractString
        link::String
        width::Int
    end

`LinkString` behaves like a sting, but it's sneaky.
It keeps track of a link which has different length as a string
and when printed. So we override a lot of the normal string's behavior
to get it to work with renderables.
"""
struct LinkString <: AbstractString
    link::String
    width::Int
end

"""
    LinkString(s::String)

Construct a LinkString from a normal string, taking
into account that there might be a link in there, 
so get the right width.
"""
function LinkString(s::String)
    link_width, additional_text_w = 0, 0
    for line in split(s, "\n")
        link_txt = excise_link_display_text(line)
        link_width = max(link_width, width(link_txt))
        additional_text = split(remove_ansi(line), "8;;\e\\")
        length(additional_text) > 1 &&
            (additional_text_w = max(additional_text_w, width(additional_text[2])))
    end
    LinkString(s, link_width + additional_text_w + 3)
end

LinkString(l::LinkString) = l

Base.:*(s::Union{SubString,String}, l::LinkString) =
    LinkString(s * l.link, textlen(s) + l.width)
Base.:*(l::LinkString, s::Union{SubString,String}) =
    LinkString(l.link * s, textlen(s) + l.width)
Base.:/(s::Union{SubString,String}, l::LinkString) =
    LinkString(s / l.link, max(textlen(s), l.width))
Base.:/(l::LinkString, s::Union{SubString,String}) =
    LinkString(l.link / s, max(textlen(s), l.width))

Segments.Segment(l::LinkString) = Segment(l, Measure(1, l.width))
Term.textlen(l::LinkString) = l.width
Term.split_lines(l::LinkString) = Term.split_lines(l.link)

"""
    struct Link <: AbstractRenderable
        segments::Vector{Segment}
        measure::Measure
        link::LinkString
        style::String
        display_text::String
        link_dest::String
    end

A link renderable. With a link to an url or file path
and a text that gets displayed (and is clickable on most terminals).
Key to it working as a properly renderable is its `LinkString`
"""
struct Link <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
    link::LinkString
    style::String
    display_text::String
    link_dest::String
end

Base.textwidth(l::LinkString) = l.width
Base.string(l::LinkString) = l
Base.convert(::String, l) = l
Base.print(io::IO, s::LinkString) = print(io, s.link)
Base.show(io::IO, ::MIME"text/plain", l::LinkString) = print(io, l.link)

"""
    Link(
        file_path::AbstractString,
        line_number::Union{Nothing,Integer} = nothing;
        style = TERM_THEME[].link,
    )

Build a link given a file path and line number.
"""
function Link(
    file_path::AbstractString,
    line_number::Union{Nothing,Integer} = nothing,
    display_text::Union{Nothing,String} = nothing;
    style = TERM_THEME[].link,
)
    link_dest =
        isnothing(line_number) ? "file://" * file_path : "file://$file_path#$line_number"
    isnothing(display_text) &&
        (display_text = isnothing(line_number) ? file_path : "$file_path:$line_number")
    link_text =
        "{$(style)}" *
        "\e]8;;" *
        link_dest *
        "\a" *
        display_text *
        "\e]8;;\a" *
        "{/$(style)}" |> apply_style

    link_measure = Measure(1, textlen(display_text))
    link_string = LinkString(link_text, link_measure.w)

    return Link(
        [Segment(link_string)],
        link_measure,
        link_string,
        style,
        display_text,
        link_dest,
    )
end

"""
---
    Renderables.RenderableText(
        link::Link,
        args...;
        style::Union{Nothing,String} = link.style,
        width::Int = link.measure.w,
        background::Union{Nothing,String} = nothing,
        justify::Symbol = :left,
    )

Custom constructor to make a `RenderableText` out of a `Link`,
specialized to take into account `Link`'s different sizes 
between displayed and actual text.
"""
function Renderables.RenderableText(
    link::Link,
    args...;
    style::Union{Nothing,String} = link.style,
    width::Int = link.measure.w,
    background::Union{Nothing,String} = nothing,
    justify::Symbol = :left,
)
    display_text =
        pad(cleantext(link.display_text), width - link.measure.w, justify; bg = background)
    link_text =
        "{$(style)}" *
        "\x1b]8;;$(link.link_dest)\x1b\\$display_text\x1b]8;;\x1b\\" *
        "{/$(style)}" |> apply_style
    link_string = LinkString(link_text, link.measure.w)

    return RenderableText(Segment[Segment(link_string)], link.measure, style)
end

end
