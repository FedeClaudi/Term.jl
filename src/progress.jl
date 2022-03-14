module progress

import Term: int, textlen, truncate
import ..Tprint: tprint, tprintln
import ..style: apply_style
import ..consoles: console_width,
                clear,
                hide_cursor,
                show_cursor,
                line,
                erase_line,
                beginning_previous_line

import ..renderables: AbstractRenderable
import ..measure: Measure
import ..segment: Segment

export ProgressBar, update, track




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
    seg = Segment("●", "#D81B60")
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

function update(col::CompletedColumn, i::Int, N::Int, color::String)::String
    _i = "$(i)"
    _N = "$(N)"
    _i = " "^(length(_N) - length(_i)) * _i
    return apply_style("[$color bold]$_i[/$color bold]") * col.text
end


# ----------------------------- percentage column ---------------------------- #
struct PercentageColumn <: AbstractColumn
    segments::Vector
    measure::Measure
end

function PercentageColumn()
    len = 8  # "xxx.xx %
    seg = Segment(" "^len)
    return PercentageColumn([seg], seg.measure)
end

function update(col::PercentageColumn, i::Int, N::Int, args...)::String
    p = round(i / N * 100; digits=2)
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


function update(col::BarColumn, i::Int, N::Int, color::String)::String
    completed = int(col.nsegs * i/N)
    remaining = col.nsegs - completed
    return apply_style("[$color bold]" * seg^(completed) * "[/$color bold]"* " "^(remaining))
end




# ---------------------------------------------------------------------------- #
#                                  PROGESS BAR                                 #
# ---------------------------------------------------------------------------- #

seg = '━'


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
    transient::Bool
    columns::Vector{AbstractColumn}
    originalstdout  # stores a reference to the original stdout
    out  # will be used to store temporarily re-directed stdout

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
                columns::Union{Nothing, Vector{AbstractColumn}} = nothing
        )

        # use default columns layout
        if isnothing(columns)
            columns = [
                DescriptionColumn(description),
                SeparatorColumn(),
                BarColumn(),
                SeparatorColumn(),
                CompletedColumn(N),
                PercentageColumn(),
            ]
        end

        # check that width is large enough
        width = expand ? console_width() : max(width, 20)

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
            false,
            transient,
            columns,
            nothing,
        )

    end

    Base.show(io::IO, ::MIME"text/plain", pbar::ProgressBar) = print(io, "Progress bar \e[2m($(pbar.i)/$(pbar.N))\e[0m")

end

struct TempSTDOUT
    out_rd::Base.PipeEndpoint
    out_wr::Base.PipeEndpoint
    out_reader::Task
end

"""
pbar_color(pbar::ProgressBar)

Get the RGB color of of a progress bar's bar based on progress.
"""
function pbar_color(pbar::ProgressBar)
    _r = pbar.i/pbar.N
    i = .8 * _r
    g = i
    r = .9 - i

    b = max(sin(π * _r) * .7, .4)
    return "($r, $g, $b)"
end

function start(pbar::ProgressBar)
    # re-direct STDOUT
    pbar.originalstdout = stdout
    out_rd, out_wr = redirect_stdout()
    out_reader = @async read(out_rd, String)
    pbar.out = TempSTDOUT(out_rd, out_wr, out_reader)

    # start pbar
    hide_cursor()
    pbar.started = true
end

function stop(pbar::ProgressBar)
    # restore STDOUT
    redirect_stdout(pbar.originalstdout)
    close(pbar.out.out_wr)

    # print out captured content
    out = fetch(pbar.out.out_reader)
    tprint(out)
    show_cursor()
end


"""
    update(pbar::ProgressBar)

Update progress bar info and display.
"""
function update(pbar::ProgressBar)
    # check that index is in range
    pbar.i = pbar.i > pbar.N ? pbar.N : pbar.i

    # get progress bar
    color = pbar_color(pbar)

    # get columns data
    contents = map((c)->update(c, pbar.i, pbar.N, color), pbar.columns)

    # start & print progress bar
    if !pbar.started
        start(pbar)
        tprint(pbar.originalstdout, contents...)
        line(pbar.originalstdout)  # any stdout will happen on a new line
    else
        # erase_line()  # delete previous pbar
        beginning_previous_line(pbar.originalstdout)
        erase_line(pbar.originalstdout)
        tprint(pbar.originalstdout, contents...)
        line(pbar.originalstdout)
    end

    # update counter
    pbar.i += 1

    # check if done
    if pbar.i > pbar.N
        # pbar.transient ? erase_line() : line()
        # show_cursor()
        stop(pbar)
    end

    return nothing
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
    isnothing(it) || update(e.pbar)
    return it
end

"""
Update progress bar and continue iteration.
"""
function Base.iterate(e::Track, state)
    it = iterate(e.itr, state)
    isnothing(it) || update(e.pbar)
    return it
end

Base.length(e::Track) = length(e.itr)
Base.size(e::Track) = size(e.itr)


end
