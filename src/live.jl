using Term
using REPL

using Term.Consoles
using Logging
import Random

import Term.Renderables: AbstractRenderable
import Term: Measure

# TODO use IOCapture to collect stdout output during live rendering






using Markdown
text = md"""
 # Markdown rendering in Term.jl
 ## two
 ### three
 #### four
 ##### five
 ###### six

 This is an example of markdown content rendered in Term.jl.
 You can use markdown syntax to make words **bold** and *italic* or insert `literals`.


 You markdown can include in-line latex ``\LaTeX  \frac{{1}}{{2}}`` and maths in a new line too:

 ```math
 f(a) = \frac{1}{2\pi}\int_{0}^{2\pi} (\alpha+R\cos(\theta))d\theta
 ```

 You can also have links: [Julia](http://www.julialang.org) and
 footnotes [^1] for your content [^named].

 And, of course, you can show some code too:

 ```julia
 function say_hi(x)
     print("Hellow World")
 end
 ```

 ---

 You can use "quotes" to highlight a section:

 > Multi-line quotes can be helpful to make a 
 > paragram stand out, so that users won't miss it!
 > You can use **other inline syntax** in you `quotes` too.
  
 but if you really need to grab someone's attention, use admonitions:

 !!! note
     You can use different levels

 !!! warning
     to send different messages

 !!! danger
     to your reader

 !!! tip "Wow!"
     Turns out that admonitions can be pretty useful!
     What will you use them for?

 ---

 Of course you can have classic lists:
 * item one
 * item two
 * And a sublist:
     + sub-item one
     + sub-item two

 and ordered lists too:
 1. item one
 2. item two
 3. item three


 !!! note "Tables"
     You can use the [Markdown table syntax](https://www.markdownguide.org/extended-syntax/#tables)
     to insert tables - Term.jl will convert them to Table object!

 | Term | handles | tables|
 |:---------- | ---------- |:------------:|
 | Row `1`    | Column `2` |              |
 | *Row* 2    | **Row** 2  | Column ``3`` |


 ----

 This is where you print the content of your foot notes:

 [^1]: Numbered footnote text.

 [^note]:
     Named footnote text containing several toplevel elements.


 """

import Term.TermMarkdown: parse_md
import Term: Renderable, Measure


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

function update_live(live::Live, x)
    !isnothing(live.prevcontent) && begin
        nlines = live.prevcontent.measure.h + 1
        for _ in 1:nlines
            up(live.ioc)
            erase_line(live.ioc)
        end
    end

    println(live.ioc, x)
    live.prevcontent = x

    write(stdout, take!(live.iob))
end

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


function pager(content::String)
    i = 0
    W = Measure(content).w
    content = split(content, "\n")

    @live while i < length(content) - 10
        sleep(rand(.25:.05:.5) / 4)
        i += 1
        
        page = join(content[i:i+10], "\n")
        Panel(page, fit=false, width=W+10, padding=(4, 4, 1, 1), 
            subtitle="Lines: $i:$(i+10)", subtitle_style="bold dim", subtitle_justify=:right,
            style="$pink", title="Term.jl PAGER", title_style="bold white"
            )
    end

    println("done")
end

pager(parse_md(text))


