module progress

using Dates
import Parameters: @with_kw
import UUIDs: UUID

import Term: int, textlen, truncate, loop_last, get_file_format
import ..Tprint: tprint, tprintln
import ..style: apply_style
import ..console: console_width,
                hide_cursor,
                show_cursor,
                move_to_line,
                cleartoend,
                change_scroll_region,
                console_height,
                up, down,
                erase_line,
                savecursor,
                restorecursor

import ..renderables: AbstractRenderable
import ..measure: Measure
import ..segment: Segment
import ..color: RGBColor
import ..layout: hLine

export ProgressBar, ProgressJob, addjob!, start!, stop!, update!, removejob!, with, @track



# ---------------------------------------------------------------------------- #
#                               PROGRESS BAR JOB                               #
# ---------------------------------------------------------------------------- #

# ------------------------------- constructors ------------------------------- #
"""
    ProgressJob

Single `job` whose progress we're tracking with a progress bar.

Each progress bar can have multiple jobs running at the same time, and more can
be added/removed at any time. Each `ProgressJob` keeps track of the state (progress)
of each of these jobs. `ProgressJob` is also rendered to create the visual display
of the progress bar. 

Arguments:
- `id` specifies the job;s unique id
- `i`: keeps track of the progress (number of completed steps)
- `N`: total number of steps in the task at hand. Optional, set to `nothing` when not known
- `description`: a bit of text describing what the job is
- `columns`: set of `AbstractColumn` used to represent the job's information
- `columns_kwargs`: additional information passed to each column when created (e.g. to set style)
- `width`: width of the progress bar display
- `started`: whether the job was started or not.
- `stopped`: whether the job was stopped (finished job)
- `startime`: time at which job was started
- `stoptime`: time at which job was stopped
- `transient`: if truee the job's visual display disappears when `stopped=true`
"""
mutable struct ProgressJob
    id::Union{Int, UUID}

    i::Int   # keep track of progress
    N::Union{Nothing, Int}

    description::String
    columns
    columns_kwargs::Dict
    width::Int

    started::Bool
    finished::Bool
    startime::Union{Nothing, DateTime}
    stoptime::Union{Nothing, DateTime}
    transient::Bool


    """
        ProgressJob(
            id::Union{Int, UUID},
            N::Union{Int, Nothing},
            description::String,
            columns::Vector{DataType},
            width::Int,
            columns_kwargs::Dict,
            transient::Bool,
        )

    Constructor for a `ProgressJob`.
    
    See also [`addjob!`](@ref), [`start!`](@ref), [`stop!`](@ref), [`update!`](@ref), [`redender`](@ref)
    """
    function ProgressJob(
            id::Union{Int, UUID},
            N::Union{Int, Nothing},
            description::String,
            columns::Vector{DataType},
            width::Int,
            columns_kwargs::Dict,
            transient::Bool,
        )
        return new(
            id, isnothing(N) ? 0 : 1, N, description, columns, columns_kwargs, width, false, false, nothing, nothing, transient
        )
    end
end

Base.show(io::IO, ::MIME"text/plain", job::ProgressJob) = print(io, "Progress job $(job.id) \e[2m(started: $(job.started))\e[0m")

"""
    start!(job::ProgressJob)

Start a newly created `ProgressJob`.

When starting a job, take care of creating instance of `AbstractColumns`
to display the job's progress. If `N` is nothing, remove any `ProgressColumn`
"""
function start!(job::ProgressJob)
    job.started && return

    # if the job doesn't have a defined `N`, we can't have a progress column display
    if isnothing(job.N)
        filter!(c->c != ProgressColumn, job.columns)

        # but we should have a spinner column if there isnt one.
        if !any(job.columns .== SpinnerColumn)
            push!(job.columns, SpinnerColumn)
        end
    end

    # create columns type instances, passing the appropriate keyword arguments
    csymbol(c) = Symbol(split(string(c), ".")[end])
    makecol(c) = haskey(job.columns_kwargs, csymbol(c)) ? c(job; job.columns_kwargs[csymbol(c)]...) : c(job)
    job.columns = map(
        c -> makecol(c), job.columns
    )
    
    # if there's a progress column, set its width
    if !isnothing(job.N) && any(map(c -> c isa ProgressColumn, job.columns))
        # get the progress column width
        spaces = length(job.columns)-1
        colwidths = sum(c -> c.measure.w, job.columns)
        bcol_width = job.width - colwidths - spaces
        
        # set width
        setwidth!.(job.columns, bcol_width)
    end

    # start job
    job.started = true
    job.startime = now()
    return nothing
end

"""
    update!(job::ProgressJob; i = nothing)

Update a job's progress `i` by setting its value or adding `+1`.
"""
function update!(job::ProgressJob; i = nothing)
    (!isnothing(job.N) && job.i >= job.N) && return stop!(job)

    job.i = isnothing(i) ? job.i + 1 : job.i + i
    nothing
end

"""
    stop!(job::ProgressJob)

Stop a running job.
"""
function stop!(job::ProgressJob)
    job.stoptime = now()
    job.finished = true
    nothing
end



# ---------------------------------------------------------------------------- #
#                                    COLUMNS                                   #
# ---------------------------------------------------------------------------- #
# load columns types definitions
include("_progress.jl")


# ---------------------------------------------------------------------------- #
#                                  PROGRESS BAR                                #
# ---------------------------------------------------------------------------- #
"""
    RenderStatus

Keep track of rendering information for a `ProgressBar`
"""
Base.@kwdef mutable struct RenderStatus
    rendered::Bool = false
    nlines::Int = 0
    maxnlines::Int = 0
    hline::String = ""
    scrollline::Int = 0
end


# ------------------------------- constructors ------------------------------- #
"""
    ProgressBar

Progressbar Type, stores information required
to render progress bar renderables for each `ProgressJob` assigned.

ProgressBar takes care of the work needed to setup/update progress bar(s)
visualizations. Each individual bar corresponds to a (running) `ProgressJob`
and `ProgressJob` itself is what actually creates the visuals. 
Most of the work done by ProgressBar is to handling terminal stuff, move 
cursor position, change scrolling regions, clear/update sections etc.


Arguments:
    - `jobs`: vector of `ProgressJob` to assign to the progress bar (more can added later)
    - `width`: width of the visualization, if `expand=false`
    - `columns`: which columns to show? Either a vector of column types or the name of a preset
    - `column_kwargs`: keyword arguments to pass to each column
    - `transient`: if true jobs disappear when done (and the whole pbar when all jobs are done)
    - `colors`: set of 3 `RGBColor` to change the color of the progress bar with progress
    - `Δt`: delay between refreshes of the visualization.
    - `buff`: `IOBuffer` used to render the progress bars
    - `running`: true if the progress bar is active
    - `paused`: false when the bar is running but briefly paused (e.g. to update `jobs`)
    - `task`: references a `Task` for updating the progress bar in parallel
    - `renderstatus`: a `RenderStatus` instance.
"""
mutable struct ProgressBar
    jobs::Vector{ProgressJob}
    width::Int

    columns::Vector{DataType}
    columns_kwargs::Dict

    transient::Bool
    colors::Vector{RGBColor}
    Δt::Float64

    buff::IOBuffer  # will be used to store temporarily re-directed stdout
    running::Bool
    paused::Bool
    task::Union{Task, Nothing}
    renderstatus
end

"""
    ProgressBar(;
        width::Int=88,
        columns::Union{Vector{DataType}, Symbol} = :default,
        columns_kwargs::Dict = Dict(),
        expand::Bool=false,
        transient::Bool = false,
        colors::Vector{RGBColor} = [
            RGBColor("(1, .05, .05)"),
            RGBColor("(.05, .05, 1)"),
            RGBColor("(.05, 1, .05)"),
        ],
        refresh_rate::Int=60,  # FPS of rendering
    )

Create a ProgressBar instance.
"""
function ProgressBar(;
    width::Int=88,
    columns::Union{Vector{DataType}, Symbol} = :default,
    columns_kwargs::Dict = Dict(),
    expand::Bool=false,
    transient::Bool = false,
    colors::Vector{RGBColor} = [
        RGBColor("(1, .05, .05)"),
        RGBColor("(.05, .05, 1)"),
        RGBColor("(.05, 1, .05)"),
    ],
    refresh_rate::Int=60,  # FPS of rendering
)

    columns = columns isa Symbol ? get_columns(columns) : columns

    # check that width is large enough
    width = expand ? console_width()-5 : min(max(width, 20), console_width()-5)

    return ProgressBar(
            Vector{ProgressJob}(),
            width,
            columns,
            columns_kwargs,
            transient,
            colors,
            1/refresh_rate,
            IOBuffer(), false, false, nothing, RenderStatus()
        )
end

Base.show(io::IO, ::MIME"text/plain", pbar::ProgressBar) = print(io, "Progress bar \e[2m($(length(pbar.jobs)) jobs)\e[0m")


# ---------------------------------------------------------------------------- #
#                                    METHODS                                   #
# ---------------------------------------------------------------------------- #
# --------------------------------- edit pbar -------------------------------- #
"""
    addjob!(
            pbar::ProgressBar;
            description::String="Running...",
            N::Union{Int, Nothing}=nothing,
            start::Bool=true,
            transient::Bool=false,
            id=nothing
        )::ProgressJob

Add a new `ProgressJob` to a running `ProgressBar`

See also: [`removejob!`](@ref), [`getjob`](@ref)
"""
function addjob!(
        pbar::ProgressBar;
        description::String="Running...",
        N::Union{Int, Nothing}=nothing,
        start::Bool=true,
        transient::Bool=false,
        id=nothing
    )::ProgressJob

    pbar.running && print("\n")

    # create Job
    pbar.paused = true
    id = isnothing(id) ? length(pbar.jobs) + 1 : id
    job = ProgressJob(id, N, description, pbar.columns, pbar.width, pbar.columns_kwargs, transient)

    # start job
    start && start!(job)
    push!(pbar.jobs, job)
    pbar.paused = false
    return job
end

"""
    removejob!(pbar::ProgressBar, job::ProgressJob)

Remove a `ProgressJob` from a `ProgressBar`.

See also: [`addjob!`](@ref), [`getjob`](@ref)
"""
function removejob!(pbar::ProgressBar, job::ProgressJob)
    pbar.paused = true
    stop!(job)
    deleteat!(pbar.jobs, findfirst(j -> j.id == job.id, pbar.jobs))
    pbar.paused = false
end

"""
    getjob(pbar::ProgressBar, id)

Get a `ProgressBar`'s `ProgressJob` by `id`.
"""
function getjob(pbar::ProgressBar, id)
    idx = findfirst(j -> j.id == id, pbar.jobs)
    isnothing(idx) && return nothing
    return pbar.jobs[idx]
end

"""
    start!(pbar::ProgressBar)

Start a `ProgressBar` and run a `Task` to update its visuals.

Starts a parallel `Task` for updating the `ProgressBar`
visualization while other code runs. The task is stopped
when the progress bar is set to have `running=false`

See also [`stop!`](@ref)
"""
function start!(pbar::ProgressBar)
    pbar.running = true
    
    print("\n"^(length(pbar.jobs)))

    pbar.task = @task begin
        while pbar.running
            pbar.paused || render(pbar)
            sleep(pbar.Δt)
        end
    end
    schedule(pbar.task)
    return nothing
end

"""
    stop!(pbar::ProgressBar)

Stop a running `ProgressBar`.

Stops the `Task` updating the progress bar 
visuals too, and if the progress bar was
`transient` it clears up the visuals.
"""
function stop!(pbar::ProgressBar)
    pbar.paused = true
    pbar.running = false

    # if transient, delete 
    if pbar.transient
        # move cursor to stale scrollregion and clear
        move_to_line(stdout, console_height())
        for i in 1:pbar.renderstatus.nlines+2
            erase_line(stdout)
            up(stdout)
        end
    else
        print("\n")
    end
    
    # restore scrollbar region
    change_scroll_region(stdout, console_height())
    show_cursor()
    pbar.transient || print("\n")
    return nothing
end

# --------------------------------- rendering -------------------------------- #
"""
    render(job::ProgressJob, pbar::ProgressBar)::String

Render a `ProgressJob`
"""
function render(job::ProgressJob, pbar::ProgressBar)::String
    color = jobcolor(pbar, job)
    return apply_style(join(update!.(job.columns, color), " "))
end

"""
    render(job::ProgressJob, pbar::ProgressBar)::String

Render a `ProgressJob`
"""
function render(job::ProgressJob)::String
    color = jobcolor(job)
    return apply_style(join(update!.(job.columns, color), " "))
end

"""
    render(job::ProgressJob, pbar::ProgressBar)::String

Render a `ProgressBar`.

When a progress bar is first rendered, this function uses
ANSI codes to change the scrolling region of the terminal 
window to create a space at the bottom where the bar's visuals
can be displayed. This allows for thext printed to `stdout` to
still be visualized. On subsequent calls, this function 
ensures that the height of the reserved space matches the
number of running jobs.

All fo this requires a bit of careful work in moving the
cursor around and doing ANSI magic.
"""
function render(pbar::ProgressBar)
    # check if running
    pbar.running || return nothing
    
    # remove completed, transient jobs
    for job in pbar.jobs
        if job.finished && job.transient
            removejob!(pbar, job)
        end
    end

    # get variables
    njobs, height = length(pbar.jobs)+1, console_height()
    iob = pbar.buff

    # on the first render, create sticky region
    if !pbar.renderstatus.rendered
        print(iob, "\n"^(njobs))
        pbar.renderstatus.scrollline = height - njobs
        change_scroll_region(iob, pbar.renderstatus.scrollline)

        pbar.renderstatus.rendered = true
        pbar.renderstatus.hline = string(
            hLine(pbar.width, "progress"; style="blue dim")
        ) * "\n"
        pbar.renderstatus.nlines = njobs
        pbar.renderstatus.maxnlines = njobs

    elseif njobs > pbar.renderstatus.maxnlines
        # if we need more lines, scroll
        write(iob, "\n"^(njobs - pbar.renderstatus.maxnlines))
        
        # set scroll region
        pbar.renderstatus.maxnlines = njobs
        pbar.renderstatus.scrollline =  height - pbar.renderstatus.maxnlines
        change_scroll_region(iob, pbar.renderstatus.scrollline)
    end
    
    # move cursor to scrollregion and clear
    move_to_line(iob, pbar.renderstatus.scrollline + 1)
    cleartoend(iob)

    # render the progressbars
    write(iob, pbar.renderstatus.hline)
    for (last, job) in loop_last(pbar.jobs)
        contents = render(job, pbar)
        coda = last ? "" : "\n"
        write(iob, contents * coda)
    end

    # restore position and write
    move_to_line(iob, pbar.renderstatus.scrollline)
    write(stdout, take!(iob))
end


# ---------------------------------------------------------------------------- #
#                                     WITH                                     #
# ---------------------------------------------------------------------------- #
"""
    with(expr, pbar::ProgressBar)

Wrap an expression to run code in the context of a progress bar.

Ensures that the progress bar is correctly created and distroyed
even if code within the loop whose progress we're monitoring causes
and error. Since `render` changes the scrollregion in the terminal, 
we need to make sure that we can restore things no matter what.

# Examples
```julia
pbar = ProgressBar()
with(pbar) do
    job = addjob!(pbar; description="Running")
    for i in 1:500
        update!(job)
        sleep(.0025)
    end
end
```
"""
function with(expr, pbar::ProgressBar)
    val = nothing
    try
        start!(pbar)
        render(pbar)
        val = expr()
        render(pbar)
    catch  err
        stop!(pbar)
        rethrow()
        quit()
    end
    stop!(pbar)
    return val
end

# ---------------------------------------------------------------------------- #
#                                     TRACK                                    #
# ---------------------------------------------------------------------------- #

"""
    @track(ex)

Macro to wrap a loop in a progress bar.

Like [`with`](@ref) it wraps the expression code
in a try/finally statement to ensure that the
progress bar is correctly stopped in any situation.

# Examples
```julia
@track for i in 1:10
    sleep(0.1)
end
```
"""
macro track(ex)
    iter = esc(ex.args[1].args[2])
    i = esc(ex.args[1].args[1])
    body = esc(ex.args[2])
    quote
        __pbar = ProgressBar()
        __pbarjob = addjob!(__pbar; N=length($iter))
        with(__pbar) do
            for $i in $iter
                update!(__pbarjob)
                $body
            end
        end
    end
end


# ------------------------------- general utils ------------------------------ #
"""
jobcolor(job::ProgressJob)

Get the RGB color of of a progress bar's bar based on progress.
"""
function jobcolor(pbar::ProgressBar, job::ProgressJob)
    isnothing(job.N) && return "white"

    α = .8 * job.i/job.N
    β = max(sin(π * job.i/job.N) * .7, .4)

    c1, c2, c3 = pbar.colors
    r = string(int((.8 - α) * c1.r + β * c2.r + α * c3.r))
    g = string(int((.8 - α) * c1.g + β * c2.g + α * c3.g))
    b = string(int((.8 - α) * c1.b + β * c2.b + α * c3.b))
    return "(" * r * ", " * g * ", " * b * ")"
end


const PbarCol1 = RGBColor("(1, .05, .05)")
const PbarCol2 = RGBColor("(.05, .05, 1)")
const PbarCol3 = RGBColor("(.05, 1, .05)")

function jobcolor(job::ProgressJob)
    isnothing(job.N) && return "white"

    α = .8 * job.i/job.N
    β = max(sin(π * job.i/job.N) * .7, .4)

    c1, c2, c3 = PbarCol1, PbarCol2, PbarCol3
    r = string(int((.8 - α) * c1.r + β * c2.r + α * c3.r))
    g = string(int((.8 - α) * c1.g + β * c2.g + α * c3.g))
    b = string(int((.8 - α) * c1.b + β * c2.b + α * c3.b))
    return "(" * r * ", " * g * ", " * b * ")"
end

end
