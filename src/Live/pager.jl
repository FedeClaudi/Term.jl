"""
    mutable struct Pager <: AbstractLiveDisplay
        internals::LiveInternals
        measure::Measure
        content::Vector{String}
        title::String
        tot_lines::Int
        curr_line::Int
        page_lines::Int
    end

Live renderables to display long texts in the terminal, a few lines at the time. 
"""
@with_repr mutable struct Pager <: AbstractLiveDisplay
    internals::LiveInternals
    measure::Measure
    content::Vector{String}
    title::String
    tot_lines::Int
    curr_line::Int
    page_lines::Int
end

"""
    function Pager(content::String; page_lines = 10, title = "Term.jl PAGER", width=console_width())

Construct a Pager for a given piece of text.
"""
function Pager(content::String; page_lines = 10, title = "Term.jl PAGER", width=console_width())
    content = split(
        string(
            RenderableText(content; width=width-19)
        ), "\n")

    return Pager(
        LiveInternals(),
        Measure(page_lines+4, width),
        content,
        title,
        length(content),
        1,
        page_lines,
    )
end

# ---------------------------------- frame  ---------------------------------- #

"""
    frame(pager::Pager)::AbstractRenderable

Create a Panel with, as content, the currently visualized lines in the Pager.
"""
function frame(pager::Pager)::AbstractRenderable
    i, Δi = pager.curr_line, pager.page_lines
    page = join(pager.content[i:min(pager.tot_lines, i + Δi)], "\n")
    Panel(
        page,
        fit = false,
        width = pager.measure.w,
        padding = (4, 4, 1, 1),
        subtitle = "Lines: $i:$(i+Δi) of $(pager.tot_lines)",
        subtitle_style = "bold dim",
        subtitle_justify = :right,
        style = pink,
        title = pager.title,
        title_style = "bold white",
    )
end

# --------------------------------- controls --------------------------------- #
"""
- ArrowDown: move to the next line
"""
function key_press(p::Pager, ::ArrowDown)
    p.curr_line = min(p.tot_lines - p.page_lines, p.curr_line + 1)
end

"""
- ArrowUp: move to the previous line
"""
function key_press(p::Pager, ::ArrowUp)
    p.curr_line = max(1, p.curr_line - 1)
end

"""
- PageDownKey,ArrowRight: move to the next page
"""
function key_press(p::Pager, ::Union{PageDownKey,ArrowRight})
    p.curr_line = min(p.tot_lines - p.page_lines, p.curr_line + p.page_lines)
end

"""
- PageUpKey,ArrowLeft: move to the previous page
"""
function key_press(p::Pager, ::Union{PageUpKey,ArrowLeft})
    p.curr_line = max(1, p.curr_line - p.page_lines)
end

"""
- HomeKey: move to first line
"""
key_press(p::Pager, ::HomeKey) = p.curr_line = 1

"""
- EndKey: move to the last line
"""
key_press(p::Pager, ::EndKey) = p.curr_line = p.tot_lines - p.page_lines