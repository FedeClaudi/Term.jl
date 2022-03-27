module progress

using Dates
import MyterialColors: pink, yellow_dark, teal
import Parameters: @with_kw

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

export ProgressBar, ProgressJob, addjob!

# , update, track, start, stop


# ---------------------------------------------------------------------------- #
#                               PROGRESS BAR JOB                               #
# ---------------------------------------------------------------------------- #

# ------------------------------- constructors ------------------------------- #
mutable struct ProgressJob
    id::Int

    i::Int   # keep track of progress
    N::Union{Nothing, Int}
    update_every::Int

    description::String
    columns  

    started::Bool
    finished::Bool
    startime::Union{Nothing, DateTime}
    stoptime::Union{Nothing, DateTime}

    function ProgressJob(
            id::Int,
            N::Union{Int, Nothing},
            description::String,
            columns::Vector{DataType}; 
            update_every::Int=1,
        )
        return new(
            id, 1, N, update_every, description, columns, false, false, nothing, nothing
        )
    end
end

Base.show(io::IO, ::MIME"text/plain", job::ProgressJob) = print(io, "Progress job $(job.id) \e[2m(started: $(job.started))\e[0m")


function start!(job::ProgressJob)
    job.started && return

    # if the job doesn't have a defined `N`, we can't have a progress column display
    if isnothing(job.N)
        filter!(c->c != ProgressColumn, job.columns)
    end

    # create columns type instances
    job.columns = map(
        c -> eval(:($c($job))), job.columns
    )

    # if there's a progress column, set its width
    if !isnothing(job.N) && any(job.columns isa ProgressColumn)        
        # get the progress column width
        spaces = length(columns)-1
        colwidths = sum(map((c)-> c isa ProgressColumn ? 0 : c.measure.w, columns))
        bcol_width = width - colwidths - spaces

        # set width
        for col in columns
            col isa ProgressColumn && setwidth!(col, bcol_width)
        end
    end

    # start job
    job.started = true
    job.startime = now()
end

function stop!(job::ProgressJob)
    job.stoptime = now()
    job.finished = true
end


"""


# get the width of the ProgressColumn
spaces = length(columns) -1
colwidths = sum(map((c)-> c isa ProgressColumn ? 0 : c.measure.w, columns))
bcol_width = width - colwidths - spaces

# if it doesn't have a bar column, add one
bars = sum(map((c)-> c isa ProgressColumn ? 1 : 0, columns))
if bars == 0
    push!(columns, ProgressColumn())
elseif bars > 1
    bcol_width /= bars
end

# set width of bar columns
for col in columns
    col isa ProgressColumn && setwidth!(col, bcol_width)
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
"""

# ---------------------------------------------------------------------------- #
#                                    COLUMNS                                   #
# ---------------------------------------------------------------------------- #
# load columns types definitions
include("_progress.jl")


# ---------------------------------------------------------------------------- #
#                                  PROGESS BAR                                 #
# ---------------------------------------------------------------------------- #

# ------------------------------- constructors ------------------------------- #
"""
    ProgressBar

Progress bar Type, stores information required
to render a progress bar renderable.
"""
mutable struct ProgressBar
    jobs::Vector{ProgressJob}
    width::Int
    columns::Vector{DataType}

    transient::Bool
    redirectstdout::Bool
    originalstdout::Union{Nothing, IO}  # stores a reference to the original stdout
    out  # will be used to store temporarily re-directed stdout
    colors::Vector{RGBColor}

    function ProgressBar(;
        width::Int=88,
        columns::Union{Vector{DataType}, Symbol} = :default,
        expand::Bool=false,
        transient::Bool = false,
        redirectstdout::Bool = false,
        originalstdout::Union{Nothing, IO}  = nothing, # stores a reference to the original stdout
        out = nothing,  # will be used to store temporarily re-directed stdout
        colors::Vector{RGBColor} = [
            RGBColor("(1, .05, .05)"),
            RGBColor("(.05, .05, 1)"),
            RGBColor("(.05, 1, .05)"),
        ],
    )

    columns = columns isa Symbol ? get_columns(columns) : columns

    # check that width is large enough
    width = expand ? console_width()-5 : min(max(width, 20), console_width()-5)

    return new(
        Vector{ProgressJob}(),
        width,
        columns,
        transient,
        redirectstdout,
        originalstdout,
        out,
        colors
    )
end
end

Base.show(io::IO, ::MIME"text/plain", pbar::ProgressBar) = print(io, "Progress bar \e[2m($(length(pbar.jobs)) jobs)\e[0m")



# ---------------------------------- methods --------------------------------- #
function addjob!(
        pbar::ProgressBar;
        description::String="Running...",
        N::Union{Int, Nothing}=nothing,
        start::Bool=true,
        update_every::Int=1
    )::ProgressJob

    # create Job
    job = ProgressJob(length(pbar.jobs) + 1, N, description, pbar.columns; update_every=update_every)

    # start job
    start && start!(job)

    push!(pbar.jobs, job)
    return job
end



# ------------------------------- general utils ------------------------------ #
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

end
