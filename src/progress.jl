module progress

using Dates
import MyterialColors: pink, yellow_dark, teal

import Term: int, textlen, truncate
import ..Tprint: tprint, tprintln
import ..style: apply_style
import ..consoles: console_width,
                clear,
                hide_cursor,
                show_cursor,
                line,
                erase_line,
                beginning_previous_line,
                down

import ..renderables: AbstractRenderable
import ..measure: Measure
import ..segment: Segment
import ..color: RGBColor

export ProgressBar, update, track, start, stop




# ---------------------------------------------------------------------------- #
#                                    columns                                   #
# ---------------------------------------------------------------------------- #
abstract type AbstractColumn <: AbstractRenderable end



# ---------------------------- description column ---------------------------- #
struct DescriptionColumn <: AbstractColumn
    segments::Vector
    measure::Measure
    text::String
end

function DescriptionColumn(description::String)
    seg = Segment(description)
    return DescriptionColumn([seg], seg.measure, seg.text)
end

update(col::DescriptionColumn, args...)::String = col.text


# ----------------------------- separator column ----------------------------- #
struct SeparatorColumn <: AbstractColumn
    segments::Vector
    measure::Measure
    text::String
end

function SeparatorColumn()
    seg = Segment("●", pink)
    return SeparatorColumn([seg], seg.measure, seg.text)
end

update(col::SeparatorColumn, args...)::String = col.text


# ----------------------------- completed column ----------------------------- #
struct CompletedColumn <: AbstractColumn
    segments::Vector
    measure::Measure
    text::String
end

function CompletedColumn(N::Int)
    width = length("$N")*2+1
    seg = Segment(" "^width)
    text = apply_style("[white bold]/[/white bold][(.1, .8, .4) underline]$N[/(.1, .8, .4) underline]")
    return CompletedColumn([seg], seg.measure, text)
end

function update(col::CompletedColumn, i::Int, N::Int, color::String, args...)::String
    _i = "$(i)"
    _N = "$(N)"
    _i = lpad("$i", length(_N))
    return apply_style("[$color bold]$_i[/$color bold]") * col.text
end


# ----------------------------- percentage column ---------------------------- #
struct PercentageColumn <: AbstractColumn
    segments::Vector
    measure::Measure
end

function PercentageColumn()
    len = 5  # "xxx %
    seg = Segment(" "^len)
    return PercentageColumn([seg], seg.measure)
end

function update(col::PercentageColumn, i::Int, N::Int, args...)::String
    p = string(int(i / N * 100))
    p = lpad(p, col.measure.w-2)
    return "\e[2m$p %\e[0m"
end

# -------------------------------- bar column -------------------------------- #
mutable struct BarColumn <: AbstractColumn
    segments::Vector
    measure::Measure
    nsegs::Int
end

BarColumn() = BarColumn([], Measure(0, 0), 0)

function setwidth!(col::BarColumn, width::Int)
    col.measure = Measure(width, 1)
    col.nsegs = width
end



function update(col::BarColumn, i::Int, N::Int, color::String, args...)::String
    completed = int(col.nsegs * i/N)
    remaining = col.nsegs - completed

    completed = completed < 0 ? 0 : completed
    remaining = remaining < 0 ? 0 : remaining

    return apply_style("[" *color*" bold]" * '━'^(completed) * "[/"*color*" bold]"* " "^(remaining))
end


# ------------------------------ elapsed column ------------------------------ #

struct ElapsedColumn <: AbstractColumn
    segments::Vector
    measure::Measure
    style::String
end

ElapsedColumn(; style=yellow_dark) = ElapsedColumn([], Measure(6+9, 1), style)

function update(col::ElapsedColumn, i::Int, N::Int, color::String, starttime::Union{Nothing, DateTime}, args...)::String
    isnothing(starttime) && return " "^(col.measure.w)
    elapsedtime = (now() - starttime).value  # in ms

    # format elapsed message
    if elapsedtime < 1000
        msg = "$(elapsedtime)ms"
    elseif elapsedtime < (60 * 1000)
        # under a minute
        elapsed = round(elapsedtime/1000; digits=2)
        msg = "$(elapsed)s"
    else
        # show minutes
        elapsed = round(elapsedtime/(60*1000); digits=2)
        msg = "$(elapsed)min"
    end

    msg = truncate(msg, col.measure.w-9)
    msg = lpad(msg, col.measure.w-9)


    return apply_style("[$(col.style)]elapsed: $(msg)[/$(col.style)]")
end


# -------------------------------- ETA column -------------------------------- #

struct ETAColumn <: AbstractColumn
    segments::Vector
    measure::Measure
    style::String
end

ETAColumn(; style=teal) = ETAColumn([], Measure(7+11, 1), style)


function update(col::ETAColumn, i::Int, N::Int, color::String, starttime::Union{Nothing, DateTime}, args...)::String
    isnothing(starttime) && return " "^(col.measure.w)

    # get remaining time in ms
    elapsed = (now() - starttime).value  # in ms
    perc = i/N
    remaining = elapsed * (1 - perc) / perc

     # format elapsed message
    if remaining < 1000
        msg = "$(round(remaining; digits=0))ms"
    elseif remaining < (60 * 1000)
        # under a minute
        remaining = round(remaining/1000; digits=2)
        msg = "$(remaining)s"
    else
        # show minutes
        remaining = round(remaining/(60*1000); digits=2)
        msg = "$(remaining)min"
    end

    msg = truncate(msg, col.measure.w-11)
    msg = lpad(msg, col.measure.w-11)


    return apply_style("[$(col.style)]remaining: $(msg)[/$(col.style)]")


end

# ---------------------------------------------------------------------------- #
#                                  PROGESS BAR                                 #
# ---------------------------------------------------------------------------- #



function get_columns(columnsset::Symbol, description::String, N::Int)::Vector{AbstractColumn}
    if columnsset == :minimal
        return [
            DescriptionColumn(description),
            BarColumn(),
        ]
    elseif columnsset == :default
        return [
            DescriptionColumn(description),
            SeparatorColumn(),
            BarColumn(),
            SeparatorColumn(),
            CompletedColumn(N),
            PercentageColumn(),
        ]
    else
        # extensive
        return [
            DescriptionColumn(description),
            SeparatorColumn(),
            BarColumn(),
            SeparatorColumn(),
            CompletedColumn(N),
            PercentageColumn(),
            SeparatorColumn(),
            ElapsedColumn(),
            ETAColumn()
        ]
    end
end

"""
    ProgressBar

Progress bar Type, stores information required
to render a progress bar renderable.
"""
mutable struct ProgressBar
    i::Int
    N::Int
    width::Int
    started::Bool
    finished::Bool
    transient::Bool
    update_every::Int
    columns::Vector{AbstractColumn}
    startime::Union{Nothing, DateTime}
    stoptime::Union{Nothing, DateTime}
    redirectstdout::Bool
    originalstdout::Union{Nothing, IO}  # stores a reference to the original stdout
    out  # will be used to store temporarily re-directed stdout
    colors::Vector{RGBColor}


    """
        ProgressBar(;
            N::Int=100,
            width::Int=50,
            description::String="[#F48FB1]Progress...[/#F48FB1]",
            expand::Bool=false,
            transient=false
        )   
    
    Construct a `ProgressBar` with minimal required arguments.

    As part of the construction, compute the size of the bar
    itself, based on the total width and the width of the text
    elements.
    """
    function ProgressBar(;
                N::Int=100,
                width::Int=88,
                description::String="[orange1 italic]Running...[/orange1 italic]",
                expand::Bool=false,
                transient=false,
                redirectstdout=true,
                columns::Union{Symbol, Vector{AbstractColumn}} = :default,
                update_every=1,
                colors::Vector{RGBColor}=[
                    RGBColor("(1, .05, .05)"),
                    RGBColor("(.05, .05, 1)"),
                    RGBColor("(.05, 1, .05)"),
                ]
        )

        # get columns if not provided
        if columns isa Symbol
            columns = get_columns(columns, description, N)
        end

        # check that width is large enough
        width = expand ? console_width()-5 : min(max(width, 20), console_width()-5)
        

        # get the width of the BarColumn
        spaces = length(columns) -1
        colwidths = sum(map((c)-> c isa BarColumn ? 0 : c.measure.w, columns))
        bcol_width = width - colwidths - spaces

        # if it doesn't have a bar column, add one
        bars = sum(map((c)-> c isa BarColumn ? 1 : 0, columns))
        if bars == 0
            push!(columns, BarColumn())
        elseif bars > 1
            bcol_width /= bars
        end

        # set width of bar columns
        for col in columns
            col isa BarColumn && setwidth!(col, bcol_width)
        end

        # create progress bar
        new(
            1,
            N,
            width,
            false, # started
            false, # finished
            transient,
            update_every,
            columns,
            nothing, # start time
            nothing, # stop time
            redirectstdout,
            nothing, # originalstdout
            nothing, # out
            colors,
        )

    end

    Base.show(io::IO, ::MIME"text/plain", pbar::ProgressBar) = print(io, "Progress bar \e[2m($(pbar.i)/$(pbar.N))\e[0m")

end

"""
pbar_color(pbar::ProgressBar)

Get the RGB color of of a progress bar's bar based on progress.
"""
function pbar_color(pbar::ProgressBar)
    α = .8 * pbar.i/pbar.N
    β = max(sin(π * pbar.i/pbar.N) * .7, .4)

    c1, c2, c3 = pbar.colors
    r = (.8 - α) * c1.r + β * c2.r + α * c3.r
    g = (.8 - α) * c1.g + β * c2.g + α * c3.g
    b = (.8 - α) * c1.b + β * c2.b + α * c3.b
    return "($(int(r)), $(int(g)), $(int(b)))"
end

"""
    TempSTDOUT

Stores information about a temporarily re-directed STDOUT
"""
struct TempSTDOUT
    out_rd::Base.PipeEndpoint
    out_wr::Base.PipeEndpoint
    out_reader::Task
end


function start(pbar::ProgressBar)
    pbar.started && return
    pbar.originalstdout = stdout
    if pbar.redirectstdout
        # re-direct STDOUT
        out_rd, out_wr = redirect_stdout()
        out_reader = @async read(out_rd, String)
        pbar.out = TempSTDOUT(out_rd, out_wr, out_reader)
    end

    # start pbar
    hide_cursor(pbar.originalstdout)
    pbar.started = true
    pbar.startime = now()
end

function stop(pbar::ProgressBar; newline=true)
    pbar.finished && return
    # remove transient progress bars
    pbar.transient && begin   
        erase_line(pbar.originalstdout)     
        beginning_previous_line(pbar.originalstdout)  
        erase_line(pbar.originalstdout) 
        # down(pbar.originalstdout)
        # erase_line(pbar.originalstdout) 
    end

    # ensure early termination adds a new line
    # pbar.i < pbar.N && line(pbar.originalstdout)
    newline && line(pbar.originalstdout)

    # restore STDOUT
    if pbar.redirectstdout
        redirect_stdout(pbar.originalstdout)
        close(pbar.out.out_wr)
        out = fetch(pbar.out.out_reader)
        tprint(out)
    end
    print("")

    # stop
    pbar.stoptime = now()
    pbar.finished = true
    show_cursor()
    
end


"""
    update(pbar::ProgressBar)

Update progress bar info and display.
"""
function update(pbar::ProgressBar)
    # start progerss bar
    pbar.started || start(pbar)
    pbar.i > pbar.N && return

    if pbar.i % pbar.update_every == 0
        # get progress bar
        color = pbar_color(pbar)

        # get columns data
        contents = map((c)->update(c, pbar.i, pbar.N, color, pbar.startime), pbar.columns)

        # print content
        pbar.i > 1 && beginning_previous_line(pbar.originalstdout)
        tprint(pbar.originalstdout, contents...)
        pbar.i < pbar. N && line(pbar.originalstdout)
    end

    # update counter
    pbar.i += 1

    # check if done and stop
    pbar.i > pbar.N && stop(pbar)

    return nothing
end


function update(pbar::ProgressBar, i::Int)
    pbar.i = i
    update(pbar)
end


# ---------------------------------------------------------------------------- #
#                                     track                                    #
# ---------------------------------------------------------------------------- #

"""
    Track

Convenience iterator to add a `ProgressBar` to `for` loops.

```Julia
for i in track(1:100)
    # ... do something
end
```

Adds a progress bar that updates for each iteration through the loop.
"""
struct Track
    itr
    pbar::ProgressBar

    Track(itr; kwargs...) = new(itr, ProgressBar(; kwargs...))
end

"""
Costructor for a `Track` object.
"""
function track(itr; kwargs...)
    Track(
        itr;
        N = length(itr),
        kwargs...
    )
end


"""
Start iteration. Crate `Progress Bar`
"""
function Base.iterate(e::Track)
    it = iterate(e.itr)
    isnothing(it) || start(e.pbar)
    isnothing(it) || update(e.pbar)
    return it
end

"""
Update progress bar and continue iteration.
"""
function Base.iterate(e::Track, state)
    it = iterate(e.itr, state)
    isnothing(it) || update(e.pbar)
    isnothing(it) && stop(e.pbar; newline=false)
    return it
end

Base.length(e::Track) = length(e.itr)
Base.size(e::Track) = size(e.itr)


end
