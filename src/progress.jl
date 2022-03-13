module progress
    import Term: int, textlen, truncate
    import ..Tprint: tprint
    import ..style: apply_style
    import ..consoles: console_width, clear, hide_cursor, show_cursor, line, erase_line

    export ProgressBar, update

    seg = '━'
    dot = apply_style("[#D81B60] ● [/#D81B60]")


"""
    ProgressBar

Progress bar Type, stores information required
to render a progress bar renderable.
"""
mutable struct ProgressBar
    i::Int
    N::Int
    width::Int
    nsegs::Int
    description::String
    started::Bool
    transient::Bool

    """
        ProgressBar(;
            N::Int=100,
            width::Int=50,
            description::String="[#F48FB1]Progress...[/#F48FB1]",
            fill::Bool=false,
            transient=false
        )   
    
    Construct a `ProgressBar` with minimal required arguments.

    As part of the construction, compute the size of the bar
    itself, based on the total width and the width of the text
    elements.
    """
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

    Base.show(io::IO, ::MIME"text/plain", pbar::ProgressBar) = print(io, "Progress bar \e[2m($(pbar.i)/$(pbar.N))\e[0m")

end

"""
pbar_color(pbar::ProgressBar)

Get the RGB color of of a progress bar's bar based on progress.
"""
function pbar_color(pbar::ProgressBar)
    i = .8 * pbar.i/pbar.N
    g = i
    r = .9 - i
    return "($r, $g, .5)"
end


"""
    update(pbar::ProgressBar)

Update progress bar info and display.
"""
function update(pbar::ProgressBar)
    # start pbar if not started
    if !pbar.started
        line()
        hide_cursor()
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

    completed = "[$color bold]$_i[/$color bold]/[(.1, .8, .5) underline]$_N[/(.1, .8, .5) underline]"
    
    # get percentage
    p = round(pbar.i / pbar.N * 100; digits=2)
    perc = " \e[2m$p %\e[0m"

    # reset line and print progress
    _bar = apply_style(pbar.description * dot * bar * dot * completed * perc)
    erase_line()
    tprint(_bar)

    # update counter
    pbar.i += 1

    # check if done
    if pbar.i > pbar.N
        pbar.transient ? erase_line() : line()
        show_cursor()
    end

    return nothing
end

end