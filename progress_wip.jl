using Revise

# Revise.revise()

# print("cacca test \x1b[{cacca}K")
# print("\e[2K\r")
# # print("\x1b[2J")
# # print("\x1b[?25h")

import Term: tprint, int, textlen, truncate
import Term.consoles: console_width
import Term.style: apply_style
import Term: make_logo, Spacer

seg = '━'
dot = "[#D81B60] ● [/#D81B60]"

mutable struct ProgressBar
    i::Int
    N::Int
    width::Int
    nsegs::Int
    description::String
    started::Bool
    transient::Bool

    function ProgressBar(;
                N::Int=100,
                width::Int=50,
                description::String="[#F48FB1]Progress...[/#F48FB1]",
                fill::Bool=false,
                transient=false
        )

        # check that width is large enough
        width = fill ? console_width() : max(width, 20)
        
        # check if the description is too long
        description = textlen(description) > width - 10 ? truncate(description, width-10) : description
        dlen = textlen(description) + 2 * textlen(dot)

        # get length of progress info
        dinfo = length("$N")*2 + 1
        dperc = 8
        
        # get the number of segments in the progress bar 
        nsegs = width - dlen - dinfo - dperc

        # @info "Created pbar" width nsegs dlen 

        # create progress bar
        new(
            1,
            N,
            width,
            nsegs,
            description,
            false,
            transient
        )

    end
end
ProgressBar(N::Int) = ProgressBar(;N=N)


Base.show(io::IO, ::MIME"text/plain", pbar::ProgressBar) = print(io, "Progress bar \e[2m($(pbar.i)/$(pbar.N))\e[0m")


function pbar_color(pbar::ProgressBar)
    i = .8 * pbar.i/pbar.N
    g = i
    r = .9 - i
    return "($r, $g, .5)"
end

function update(pbar::ProgressBar)
    # start pbar if not started
    if !pbar.started
        print("\n")
        print("\x1b[?25l")  # hide cursor
        pbar.started = true
    end

    # check that index is in range
    pbar.i = pbar.i > pbar.N ? pbar.N : pbar.i

    # get progress bar
    color = pbar_color(pbar)
    completed = int(pbar.nsegs * pbar.i/pbar.N)
    remaining = pbar.nsegs - completed
    bar = "[$color bold]" * seg^(completed) * "[/$color bold]"* " "^(remaining)

    # get completed info
    _i = "$(pbar.i)"
    _N = "$(pbar.N)"
    _i = " "^(length(_N)-length(_i)) * _i

    completed = "[$color bold]$_i[/$color bold][white]/[/white][(.1, .8, .5) underline]$_N[/(.1, .8, .5) underline]"
    
    # get percentage
    p = round(pbar.i / pbar.N * 100; digits=2)
    perc = " [dim]$p %[/dim]"

    # reset line and print progress
    _bar = apply_style(pbar.description * dot * bar * dot * completed * perc)
    tprint("\e[2K\r" * _bar)

    # update counter
    pbar.i += 1

    # check if done
    if pbar.i > pbar.N
        pbar.transient ? print("\e[2K\r") : print("\n")
        print("\x1b[?25h") # show cursor
    end

    return nothing
end

function update(pbar::ProgressBar, i::Int)
    pbar.i = i
    update(pbar)
end

clear() = print("\x1b[2J")

# # ------------------------------------ run ----------------------------------- #

N = 250
pbar = ProgressBar(;
        N=N,
        fill=true,
        width=200,
        transient=false,
        description="Made with [bold blue underline]Term[/bold blue underline]"
    )

clear()
# print("."^(pbar.width))

for i in 1:N
    update(pbar)
    sleep(.01)
end

# print("done")
logo = make_logo()
space = Spacer(int((console_width()  -logo.measure.w) / 2), logo.measure.h)
print(space * logo)