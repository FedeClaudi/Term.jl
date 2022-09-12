mutable struct Pager <: AbstractLiveDisplay
    internals::LiveInternals
    content::Vector{String}
    title::String
    tot_lines::Int
    curr_line::Int
    page_lines::Int
    w::Int
end

function Pager(content::String; page_lines=10, title="Term.jl PAGER")
    # content = string(RenderableText(content)) # ; width=displaysize(stdout)[2]-10))
    content = split(content, "\n")
    return Pager(
        LiveInternals(),
        content,
        title,
        length(content),
        1,
        page_lines,
        Measure(content).w
    )
end


# ---------------------------------- frame  ---------------------------------- #
function frame(pager::Pager)::AbstractRenderable
    i, Δi = pager.curr_line, pager.page_lines
    page = join(pager.content[i:min(pager.tot_lines, i+Δi)], "\n")
    Panel(
        page, 
        fit=false, 
        width=pager.w+10, 
        padding=(4, 4, 1, 1), 
        subtitle="Lines: $i:$(i+Δi) of $(pager.tot_lines)",
        subtitle_style="bold dim",
        subtitle_justify=:right,
        style=pink,
        title=pager.title,
        title_style="bold white"
        )
end


# --------------------------------- controls --------------------------------- #
function key_press(p::Pager, ::ArrowDown) 
    p.curr_line = min(p.tot_lines-p.page_lines, p.curr_line+1)
end
function key_press(p::Pager, ::ArrowUp)
    p.curr_line = max(1, p.curr_line-1)
end

function key_press(p::Pager, ::Union{PageDownKey, ArrowRight}) 
    p.curr_line = min(p.tot_lines-p.page_lines, p.curr_line+p.page_lines)
end
function key_press(p::Pager, ::Union{PageUpKey, ArrowLeft})
    p.curr_line = max(1, p.curr_line-p.page_lines)
end

key_press(p::Pager, ::HomeKey) = p.curr_line = 1
key_press(p::Pager, ::EndKey) = p.curr_line = p.tot_lines - p.page_lines
