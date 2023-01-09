# ------------------------------- constructors ------------------------------- #
"""
A `Pager` is a widget for visualizing long texts a few lines at the time. 
It shows a few lines of a longer text and allows users to move up and down the text
using keys such as arrow up and arrow down.
"""
@with_repr mutable struct Pager <: AbstractWidget
    internals::LiveInternals
    measure::Measure
    controls::AbstractDict
    content::Vector{String}
    title::String
    tot_lines::Int
    curr_line::Int
    page_lines::Int
    on_draw::Union{Nothing,Function}
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
    ArrowUp() => prev_line,
    HomeKey() => home,
    EndKey() => toend,
    Esc() => quit,
    'q' => quit,
    'h' => toggle_help,
)



function Pager(
    content::String;
    controls::AbstractDict = pager_controls,
    page_lines::Int = min(console_height() - 5, 25),
    title::String = "Term.jl PAGER",
    width::Int = console_width(),
    line_numbers::Bool = false,
    on_draw::Union{Nothing,Function} = nothing,
)
    page_lines = min(page_lines, console_height() - 8)

    line_numbers && (
        content = join(
            map(iln -> "{dim}$(iln[1])  {/dim}" * iln[2], enumerate(split(content, "\n"))),
            "\n",
        )
    )

    content = split(string(RenderableText(content; width = width - 6)), "\n")

    return Pager(
        LiveInternals(),
        Measure(page_lines + 4, width),
        controls,
        content,
        title,
        length(content),
        1,
        page_lines,
        on_draw,
    )
end

# ---------------------------------- frame  ---------------------------------- #

"""
    frame(pager::Pager)::AbstractRenderable

Create a Panel with, as content, the currently visualized lines in the Pager.
"""
function frame(pager::Pager; omit_panel = false)::AbstractRenderable
    isnothing(pager.on_draw) || on_draw(pager)

    i, Δi = pager.curr_line, pager.page_lines

    page = if Δi >= pager.tot_lines
        join(pager.content, "\n")
    else
        page_content = join(pager.content[i:min(pager.tot_lines, i + Δi)], "\n")

        # make a scroll bar
        page_lines = pager.page_lines
        scrollbar_lines = min(pager.page_lines, 6)
        scrollbar_lines_half = scrollbar_lines // 2
        scrollbar = vLine(scrollbar_lines; style = "white on_white")

        p = (i) / (pager.tot_lines - Δi)  # progress in the file
        # p = min(p, 0.99)

        scrollbar_center = scrollbar_lines_half + p * (page_lines - scrollbar_lines)

        # scrollbar_center = p * (page_lines) |> round |> Int
        nspaces_above = max(0, scrollbar_center - scrollbar_lines_half) |> round |> Int
        nspaces_below =
            max(0, page_lines - scrollbar_lines - nspaces_above) |> round |> Int

        scrollbar = if nspaces_above == 0
            below = RenderableText(
                join(repeat([" \n"], nspaces_below + 1));
                style = "on_gray23",
            )
            scrollbar / below
        elseif nspaces_below == 0
            above = RenderableText(
                join(repeat([" \n"], nspaces_above + 1));
                style = "on_gray23",
            )
            above / scrollbar
        else
            above = RenderableText(join(repeat([" \n"], nspaces_above)); style = "on_gray23")
            below = RenderableText(
                join(repeat([" \n"], nspaces_below));
                style = "on_gray23",
            )
            scrollbar = above / scrollbar / below
        end

        page_content * scrollbar
    end

    # return content
    omit_panel && return "  " * RenderableText(page)
    return Panel(
        page,
        fit = false,
        width = pager.measure.w,
        padding = (2, 0, 1, 0),
        subtitle = "Lines: $i:$(i+Δi) of $(pager.tot_lines)",
        subtitle_style = "bold dim",
        subtitle_justify = :right,
        style = pink,
        title = pager.title,
        title_style = "bold white",
    )
end

