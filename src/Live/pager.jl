# ------------------------------- constructors ------------------------------- #
"""
A `Pager` is a widget for visualizing long texts a few lines at the time. 
It shows a few lines of a longer text and allows users to move up and down the text
using keys such as arrow up and arrow down.
"""
@with_repr mutable struct Pager <: AbstractWidget
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
    text::AbstractString
    content::Vector{String}
    title::String
    line_numbers::Bool
    tot_lines::Int
    curr_line::Int
    page_lines::Int
    on_draw::Union{Nothing,Function}
    on_highlighted::Function
    on_not_highlighted::Function
end



# --------------------------------- controls --------------------------------- #
"""
move to the next line
"""
next_line(p::Pager, ::Union{Char, ArrowDown}) = p.curr_line = min(p.tot_lines - p.page_lines, p.curr_line + 1)

"""
move to the previous line
"""
prev_line(p::Pager, ::Union{Char, ArrowUp}) = p.curr_line = max(1, p.curr_line - 1)

"""
move to the next page
"""
next_page(p::Pager, ::Union{PageDownKey, ArrowRight, Char}) = p.curr_line = min(p.tot_lines - p.page_lines, p.curr_line + p.page_lines)


"""
move to the previous page
"""
prev_page(p::Pager, ::Union{PageUpKey, ArrowLeft, Char}) = p.curr_line = max(1, p.curr_line - p.page_lines)


"""
move to first line
"""
home(p::Pager, ::HomeKey) = p.curr_line = 1

"""
move to the last line
"""
toend(p::Pager, ::EndKey) = p.curr_line = p.tot_lines - p.page_lines



pager_controls = Dict(
    ArrowRight() => next_page,
    ']' => next_page,
    ArrowLeft() => prev_page,
    '[' => prev_page,
    ArrowDown() => next_line,
    '.' => next_line,
    ArrowUp() => prev_line,
    ',' => prev_line,
    HomeKey() => home,
    EndKey() => toend,
    Esc() => quit,
    'q' => quit,
    'h' => toggle_help,
)


"""
    reshape_pager_content(content::AbstractString, line_numbers::Bool)::Vector{string}

Turns a text into a vector of lines with the right size (and optionally line numbers)
"""
function reshape_pager_content(content::AbstractString, line_numbers::Bool, width::Int)::Vector{String}
    reshaped_content = if line_numbers == true
        join(
            map(iln -> "{dim}$(iln[1])  {/dim}" * iln[2], enumerate(split(content, "\n"))),
            "\n",
        )
    else
        content
    end

    reshaped_content = reshape_code_string(content, width - 6)
    return split(string(RenderableText(reshaped_content; width = width - 6)), "\n")
    # return split(reshaped_content, "\n")

end



function Pager(
    text::String;
    controls::AbstractDict = pager_controls,
    height = 30,
    width=console_width(),
    title::String = "Term.jl PAGER",
    line_numbers::Bool = false,
    on_draw::Union{Nothing,Function} = nothing,
    on_highlighted::Function = on_highlighted,
    on_not_highlighted::Function = on_not_highlighted,
)

    content = reshape_pager_content(text, line_numbers, width)
    return Pager(
        Measure(height, width),
        controls,
        nothing,
        text,
        content,
        title,
        line_numbers,
        length(content),
        1,
        max(height - 5, 1),
        on_draw,
        on_highlighted, on_not_highlighted,
    )
end

function on_layout_change(p::Pager, m::Measure)
    p.page_lines = max(m.h - 5, 1)
    p.content = reshape_pager_content(p.text, p.line_numbers, m.w)
    p.tot_lines = length(p.content)
    p.curr_line = min(p.curr_line, p.tot_lines - p.page_lines)
    p.measure = m
end

# ---------------------------------- frame  ---------------------------------- #


function make_page_content(pager, i, Δi)
    if Δi >= pager.tot_lines
        return join(pager.content, "\n")
    else
        return join(pager.content[i:min(pager.tot_lines, i + Δi)], "\n")
    end
end

function make_scrollbar(pager, i, Δi)
    page_lines = pager.page_lines
    scrollbar_lines = min(pager.page_lines, 6)
    scrollbar_lines_half = scrollbar_lines // 2
    scrollbar = vLine(scrollbar_lines; style = "white on_white")

    p = (i) / (pager.tot_lines - Δi)  # progress in the file
    scrollbar_center = p * (page_lines) |> round |> Int
    nspaces_above = max(0, scrollbar_center - scrollbar_lines_half) |> round |> Int
    nspaces_below =
        max(0, page_lines - scrollbar_lines - nspaces_above) |> round |> Int

    if nspaces_above == 0
        below = RenderableText(
            join(repeat([" \n"], nspaces_below + 1));
            style = "on_gray23",
        )
        return scrollbar / below
    elseif nspaces_below == 0
        above = RenderableText(
            join(repeat([" \n"], nspaces_above + 1));
            style = "on_gray23",
        )
        return above / scrollbar
    else
        above = RenderableText(join(repeat([" \n"], nspaces_above)); style = "on_gray23")
        below = RenderableText(
            join(repeat([" \n"], nspaces_below));
            style = "on_gray23",
        )
        return above / scrollbar / below
    end
end

function make_page(pager, i, Δi)
    page_content = make_page_content(pager, i, Δi)
    scrollbar = make_scrollbar(pager, i, Δi)
    return page_content * scrollbar
end


"""
    frame(pager::Pager)::AbstractRenderable

Create a Panel with, as content, the currently visualized lines in the Pager.
"""
function frame(pager::Pager; omit_panel = false)::AbstractRenderable
    isnothing(pager.on_draw) || pager.on_draw(pager)

    i, Δi = pager.curr_line, pager.page_lines
    page = make_page(pager, i, Δi)

    # return content
    omit_panel && return "  " * RenderableText(page)
    return Panel(
        page,
        fit = false,
        width = pager.measure.w,
        height = pager.measure.h,
        padding = (2, 0, 1, 0),
        subtitle = "Lines: $(max(1, i)):$(min(i+Δi, pager.tot_lines)) of $(pager.tot_lines)",
        subtitle_style = "bold dim",
        subtitle_justify = :right,
        style = pink,
        title = pager.title,
        title_style = "bold white",
    )
end

