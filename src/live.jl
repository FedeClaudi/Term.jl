using Term
using REPL

using Term.Consoles
using Logging
import Random

import Term.Renderables: AbstractRenderable
import Term: Measure

# TODO use IOCapture to collect stdout output during live rendering

import Term: Renderable, Measure

# ---------------------------------------------------------------------------- #
#                              LIVE FUNCTIONALITY                              #
# ---------------------------------------------------------------------------- #
# ----------------------------------- Live ----------------------------------- #
mutable struct Live
    iob::IOBuffer
    ioc::IOContext
    prevcontent::Union{Nothing, AbstractRenderable}

    function Live()
        iob = IOBuffer()
        ioc = IOContext(iob, :displaysize=>displaysize(stdout))
        return new(iob, ioc,  nothing)
    end
end


# ---------------------------------- update ---------------------------------- #
function update_live(live::Live, content::AbstractRenderable)
    !isnothing(live.prevcontent) && begin
        nlines = live.prevcontent.measure.h + 1
        for _ in 1:nlines
            up(live.ioc)
            erase_line(live.ioc)
        end
    end

    println(live.ioc, content)
    live.prevcontent = content

    write(stdout, take!(live.iob))
end

update_live(live::Live, content::String) = update_live(live, RenderableText(content))


# -------------------------------- @live macro ------------------------------- #
macro live(expr)
    updater = Live()

    # inject code to print the output of each loop in `expr`
    body = expr.args[2]
    body = Expr(
        body.head, 
        body.args[1:end-2]..., 
        Expr(Symbol("="), :__live_content, body.args[end-1]), 
        :(update_live($updater, __live_content)),
        body.args[end]
    )
    expr.args[2] = body

    quote
        eval($expr)
    end |> esc
end

import MyterialColors: pink


# ---------------------------------------------------------------------------- #
#                               LIVE RENDERABLES                               #
# ---------------------------------------------------------------------------- #
function pager(content::String)
    i = 0
    W = Measure(content).w
    content = split(content, "\n")

    @live while i < length(content) - 10
        sleep(rand(.25:.05:.5) / 4)
        i += 1
        
        page = join(content[i:i+10], "\n")
        Panel(page, fit=false, width=W+10, padding=(4, 4, 1, 1), 
            subtitle="Lines: $i:$(i+10)",
            subtitle_style="bold dim",
            subtitle_justify=:right,
            style="$pink",
            title="Term.jl PAGER",
            title_style="bold white"
            )
    end

    println("done")
end

pager(parse_md(text))


