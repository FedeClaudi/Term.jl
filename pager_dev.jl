include("/Users/federicoclaudi/Documents/Github/Term.jl/src/live.jl")

import Term: default_width
import Term.Measures: Measure
import MyterialColors: pink
import Suppressor: @capture_out

Base.start_reading(stdin)

mutable struct LiveInternals
    iob::IOBuffer
    ioc::IOContext
    term::AbstractTerminal
    prevcontent::Union{Nothing, AbstractRenderable}
    raw_mode_enabled::Bool
    last_update::Union{Nothing, Int}

    function LiveInternals()
        # get output buffers
        iob = IOBuffer()
        ioc = IOContext(iob, :displaysize=>displaysize(stdout))

        # prepare terminal 
        raw_mode_enabled = try
            REPL.Terminals.raw!(terminal, true)
            true
        catch err
            @warn "Unable to enter raw mode: " exception=(err, catch_backtrace())
            false
        end
        # hide the cursor
        raw_mode_enabled && print(terminal.out_stream, "\x1b[?25l")

        return new(iob, ioc,  terminal, nothing, raw_mode_enabled, nothing)
    end
end


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

function frame(pager::Pager)::AbstractRenderable
    i, Δi = pager.curr_line, pager.page_lines
    page = join(pager.content[i:min(pager.tot_lines, i+Δi)], "\n")
    t = round(rand(); digits=3)
    Panel(page, 
        fit=false, 
        width=max(default_width(), pager.w+10), 
        padding=(4, 4, 1, 1), 
        subtitle="Lines: $i:$(i+Δi) of $(pager.tot_lines)",
        subtitle_style="bold dim",
        subtitle_justify=:right,
        style=pink,
        title=pager.title,
        title_style="bold white"
        )
end

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

clear()
text =  @capture_out inspect(Panel; documentation=true, supertypes=false)
# text = join(rand("\nasdasd\n \n asd ", 1000))
pager = Pager(text; page_lines=30, title="inspect(Panel)")
while true
    update!(pager) || break
end
stop!(pager)
println("done")

