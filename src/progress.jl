module Progress

using Dates
import Parameters: @with_kw
import UUIDs: UUID

import Term:
    rint, textlen, str_trunc, loop_last, get_file_format, update!, default_width, TERM_THEME
import ..Tprint: tprint, tprintln
import ..Style: apply_style
import ..Consoles:
    console_width,
    hide_cursor,
    show_cursor,
    move_to_line,
    cleartoend,
    change_scroll_region,
    console_height,
    up,
    down,
    erase_line,
    savecursor,
    restorecursor

import ..Renderables: AbstractRenderable
import ..Measures: Measure
import ..Segments: Segment
import ..Colors: RGBColor
import ..Layout: hLine

export ProgressBar,
    ProgressJob,
    addjob!,
    start!,
    stop!,
    update!,
    removejob!,
    with,
    @track,
    render,
    foreachprogress

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
    id::Union{Int,UUID}

    i::Int   # keep track of progress
    N::Union{Nothing,Int}

    description::String
    columns::Any
    columns_kwargs::Dict
    width::Int

    started::Bool
    finished::Bool
    startime::Union{Nothing,DateTime}
    stoptime::Union{Nothing,DateTime}
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
        id::Union{Int,UUID},
        N::Union{Int,Nothing},
        description::String,
        columns::Vector{DataType},
        width::Int,
        columns_kwargs::Dict,
        transient::Bool,
    )
        return new(
            id,
            isnothing(N) ? 0 : 1,
            N,
            description,
            columns,
            columns_kwargs,
            width,
            false,
            false,
            nothing,
            nothing,
            transient,
        )
    end
end

Base.show(io::IO, ::MIME"text/plain", job::ProgressJob) =
    print(io, "Progress job $(job.id) \e[2m(started: $(job.started))\e[0m")

"""
    start!(job::ProgressJob)

Start a newly created `ProgressJob`.

When starting a job, take care of creating instance of `AbstractColumns`
to display the job's progress. If `N` is nothing, remove any `ProgressColumn`
"""
function start!(job::ProgressJob)
    job.started && return nothing

    # if the job doesn't have a defined `N`, we can't have a progress column display
    if isnothing(job.N)
        filter!(c -> c != ProgressColumn, job.columns)

        # but we should have a spinner column if there isnt one.
        !any(job.columns .== SpinnerColumn) && push!(job.columns, SpinnerColumn)
    end

    # create columns type instances, passing the appropriate keyword arguments
    csymbol(c) = Symbol(split(string(c), ".")[end])
    function makecol(c)
        return if haskey(job.columns_kwargs, csymbol(c))
            c(job; job.columns_kwargs[csymbol(c)]...)
        else
            c(job)
        end
    end
    job.columns = map(c -> makecol(c), job.columns)

    # if there's a progress column, set its width
    if !isnothing(job.N) && any(map(c -> c isa ProgressColumn, job.columns))
        # get the progress column width
        spaces = length(job.columns) - 1
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
    (!isnothing(job.N) && job.i ≥ job.N) && return stop!(job)

    job.i += something(i, 1)
    return nothing
end

"""
    stop!(job::ProgressJob)

Stop a running job.
"""
function stop!(job::ProgressJob)
    job.stoptime = now()
    job.finished = true
    sleep(0.05)
    return nothing
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
    colors::Union{String,Vector{RGBColor}}
    Δt::Float64

    buff::IOBuffer  # will be used to store temporarily re-directed stdout
    running::Bool
    paused::Bool
    task::Union{Task,Nothing}
    renderstatus::Any
end

"""
    ProgressBar(;
        width::Int=$(default_width()),
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
    width::Int                              = default_width(),
    columns::Union{Vector{DataType},Symbol} = :default,
    columns_kwargs::Dict                    = Dict(),
    expand::Bool                            = false,
    transient::Bool                         = false,
    colors::Union{String,Vector{RGBColor}}  = [RGBColor("(1, .05, .05)"), RGBColor("(.05, .05, 1)"), RGBColor("(.05, 1, .05)")],
    refresh_rate::Int                       = 60,  # FPS of rendering
)
    columns = columns isa Symbol ? get_columns(columns) : columns

    # check that width is large enough
    width = expand ? console_width() - 5 : min(max(width, 20), console_width() - 5)

    return ProgressBar(
        Vector{ProgressJob}(),
        width,
        columns,
        columns_kwargs,
        transient,
        colors,
        1 / refresh_rate,
        IOBuffer(),
        false,
        false,
        nothing,
        RenderStatus(),
    )
end

Base.show(io::IO, ::MIME"text/plain", pbar::ProgressBar) =
    print(io, "Progress bar \e[2m($(length(pbar.jobs)) jobs)\e[0m")

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
    description::String = "Running...",
    N::Union{Int,Nothing} = nothing,
    start::Bool = true,
    transient::Bool = false,
    id = nothing,
    columns_kwargs::Dict = Dict(),
)::ProgressJob
    pbar.running && print("\n")

    # create Job
    pbar.paused = true
    id = isnothing(id) ? length(pbar.jobs) + 1 : id
    kwargs = merge(pbar.columns_kwargs, columns_kwargs)
    job = ProgressJob(id, N, description, pbar.columns, pbar.width, kwargs, transient)

    # start job
    start && start!(job)
    push!(pbar.jobs, job)
    pbar.paused = false
    render(job, pbar)
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
    return pbar.paused = false
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
        for i in 1:(pbar.renderstatus.nlines + 2)
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
    njobs, height = length(pbar.jobs) + 1, console_height()
    iob = pbar.buff

    # on the first render, create sticky region
    if !pbar.renderstatus.rendered
        print(iob, "\n"^(njobs))
        pbar.renderstatus.scrollline = height - njobs
        change_scroll_region(iob, pbar.renderstatus.scrollline)

        pbar.renderstatus.rendered = true
        pbar.renderstatus.hline =
            string(hLine(pbar.width, "progress"; style = "blue dim")) * "\n"
        pbar.renderstatus.nlines = njobs
        pbar.renderstatus.maxnlines = njobs

    elseif njobs > pbar.renderstatus.maxnlines
        # if we need more lines, scroll
        write(iob, "\n"^(njobs - pbar.renderstatus.maxnlines))

        # set scroll region
        pbar.renderstatus.maxnlines = njobs
        pbar.renderstatus.scrollline = height - pbar.renderstatus.maxnlines
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
    return print(String(take!(iob)))
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
    # @info expr expr.args

    val = nothing
    try
        start!(pbar)

        task = Threads.@spawn expr()
        while !istaskdone(task) && pbar.running
            pbar.paused || render(pbar)
            sleep(pbar.Δt)
        end
        stop!(pbar)
        val = fetch(task)
    catch err
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
        __pbarjob = addjob!(__pbar; N = length($iter))
        with(__pbar) do
            for $i in $iter
                update!(__pbarjob)
                $body
            end
        end
    end
end

const FOREACH_PROGRESS = ProgressBar(transient = true)

"""
    foreachprogress(f, iter[, pbar; parallel=false, transient=true, description])

Apply `f` to every element in iterator `iter`, showing a progress bar.
This function can be nested.

## Arguments

- `pbar::Term.Progress.ProgressBar = Term.FOREACH_PROGRESS`: The progress bar to use. By
    default, uses a global progress bar, but it is recommended to explicitly pass in
    a progress bar.
- `parallel`: Whether to use `Threads.@threads` to speed up the loop.
- `transient = true`: See `Term.Progress.addjob!`
- `description = true`: See `Term.Progress.addjob!`

## Examples

Simple loop passing in a progress bar:

```julia
foreachprogress(1:10, Term.ProgressBar(); description = "Working...") do i
    @info i
    sleep(0.1)
end
```

Simple loop using the global progress bar (use with care):

```julia
foreachprogress(1:10; description = "Working...") do i
    @info i
    sleep(0.1)
end
```

Nesting a loop inside another:

```julia
pbar = Term.ProgressBar()
foreachprogress(1:100, pbar,   description = "Outer    ", parallel=true) do i
    foreachprogress(1:5, pbar, description = "    Inner") do j
        sleep(rand() / 5)
    end
end
```

Speeding up the loop using threads by passing `parallel`:

```julia
foreachprogress(1:50; description = "Working...", parallel=true) do i
    @info i
    sleep(0.1)
end
```
"""
function foreachprogress(
    f,
    iter,
    pbar = FOREACH_PROGRESS;
    n = _getn(iter),
    transient = true,
    parallel = false,
    columns_kwargs = Dict(),
    kwargs...,
)
    task = nothing
    try
        # Only handle rendering of progress bar if it is not already running.
        # This allows nesting of `foreachprogress`
        if !pbar.running
            # If starting the progress bar, clear any previous jobs
            pbar.jobs = ProgressJob[]
            start!(pbar)
            task = Threads.@spawn _startrenderloop(pbar)
        end
        return

        # The job tracks the iteration through `iter`
        job = addjob!(
            pbar;
            N = n,
            transient = transient,
            columns_kwargs = columns_kwargs,
            kwargs...,
        )
        if parallel
            Threads.@threads for elem in iter
                f(elem)
                update!(job)
            end
        else
            for elem in iter
                f(elem)
                update!(job)
            end
        end
        stop!(job)
    catch
        rethrow()
    finally
        if !isnothing(task)
            stop!(pbar)
        end
    end
end

_getn(iter) = _getn(iter, Base.IteratorSize(iter))
_getn(iter, ::Union{Base.HasLength,<:Base.HasShape}) = length(iter)
_getn(_, _) = nothing

function _startrenderloop(pbar)
    while pbar.running
        pbar.paused || render(pbar)
        sleep(pbar.Δt)
    end
end

# ------------------------------- general utils ------------------------------ #
"""
jobcolor(job::ProgressJob)

Get the RGB color of of a progress bar's bar based on progress.
"""
function jobcolor(pbar::ProgressBar, job::ProgressJob)
    isnothing(job.N) && return "white"
    pbar.colors isa String && return pbar.colors

    α = 0.8 * job.i / job.N
    β = max(sin(π * job.i / job.N) * 0.7, 0.4)

    c1, c2, c3 = pbar.colors
    r = string(rint((0.8 - α) * c1.r + β * c2.r + α * c3.r))
    g = string(rint((0.8 - α) * c1.g + β * c2.g + α * c3.g))
    b = string(rint((0.8 - α) * c1.b + β * c2.b + α * c3.b))
    return "(" * r * ", " * g * ", " * b * ")"
end

const PbarCol1 = RGBColor("(1, .05, .05)")
const PbarCol2 = RGBColor("(.05, .05, 1)")
const PbarCol3 = RGBColor("(.05, 1, .05)")

function jobcolor(job::ProgressJob)
    isnothing(job.N) && return "white"

    α = 0.8 * job.i / job.N
    β = max(sin(π * job.i / job.N) * 0.7, 0.4)

    c1, c2, c3 = PbarCol1, PbarCol2, PbarCol3
    r = string(rint((0.8 - α) * c1.r + β * c2.r + α * c3.r))
    g = string(rint((0.8 - α) * c1.g + β * c2.g + α * c3.g))
    b = string(rint((0.8 - α) * c1.b + β * c2.b + α * c3.b))
    return "(" * r * ", " * g * ", " * b * ")"
end

end
