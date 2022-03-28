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
                prev_line,
                next_line

import ..renderables: AbstractRenderable
import ..measure: Measure
import ..segment: Segment
import ..color: RGBColor

export ProgressBar, ProgressJob, addjob!, start!, stop!, update!, removejob!



# ---------------------------------------------------------------------------- #
#                               PROGRESS BAR JOB                               #
# ---------------------------------------------------------------------------- #

# ------------------------------- constructors ------------------------------- #
mutable struct ProgressJob
    id::Int

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

    function ProgressJob(
            id::Int,
            N::Union{Int, Nothing},
            description::String,
            columns::Vector{DataType},
            width::Int,
            columns_kwargs::Dict,
        )
        return new(
            id, isnothing(N) ? 0 : 1, N, description, columns, columns_kwargs, width, false, false, nothing, nothing
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
        for col in job.columns
            col isa ProgressColumn && setwidth!(col, bcol_width)
        end
    end

    # start job
    job.started = true
    job.startime = now()
end

function update!(job::ProgressJob)
    (!isnothing(job.N) && job.i >= job.N) && return stop!(job)
    job.i += 1
    nothing
end

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
    columns_kwargs::Dict

    transient::Bool
    redirectstdout::Bool
    originalstdout::Union{Nothing, IO}  # stores a reference to the original stdout
    out  # will be used to store temporarily re-directed stdout
    colors::Vector{RGBColor}

    running::Bool
    paused::Bool
    Δt::Float64
    task::Union{Task, Nothing}

    function ProgressBar(;
        width::Int=88,
        columns::Union{Vector{DataType}, Symbol} = :default,
        columns_kwargs::Dict = Dict(),
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
        refresh_rate::Int=60,  # FPS of rendering
    )

    columns = columns isa Symbol ? get_columns(columns) : columns

    # check that width is large enough
    width = expand ? console_width()-5 : min(max(width, 20), console_width()-5)

    return new(
            Vector{ProgressJob}(),
            width,
            columns,
            columns_kwargs,
            transient,
            redirectstdout,
            originalstdout,
            out,
            colors,
            false,
            false,
            1/refresh_rate,
            nothing,
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
    )::ProgressJob

    # create Job
    pbar.paused = true
    job = ProgressJob(length(pbar.jobs) + 1, N, description, pbar.columns, pbar.width, pbar.columns_kwargs)

    # start job
    start && start!(job)

    pushfirst!(pbar.jobs, job)
    pbar.paused = false
    return job
end

function removejob!(pbar::ProgressBar, job::ProgressJob)
    stop!(job)
    deleteat!(pbar.jobs, findfirst(j -> j == job, pbar.jobs))
end

function start!(pbar::ProgressBar)
    pbar.running = true
    print("\n"^(length(pbar.jobs)))
    hide_cursor()

    pbar.task = @task begin
        while pbar.running
            pbar.paused || render(pbar)
            sleep(pbar.Δt)
        end
    end
    schedule(pbar.task)
    return nothing
end

function stop!(pbar::ProgressBar)
    render(pbar)
    pbar.running = false
    pbar.jobs = Vector{ProgressJob}()
    # print("\n"^(length(pbar.jobs)))
    show_cursor()
    return nothing
end


function render(pbar::ProgressBar)
    pbar.running || return nothing

    for (n,job) in enumerate(pbar.jobs)
        job.finished && continue
        color = jobcolor(pbar, job)
        contents = apply_style(join(update!.(job.columns, color), " "))
    
        # move cursor to the right place
        nshifts = string(n)
    
        # print
        prev_line(; n=nshifts)
        # erase_line()
        print(contents)
        next_line(; n=nshifts)
    end
end

# ------------------------------- general utils ------------------------------ #
"""
jobcolor(job::ProgressJob)

Get the RGB color of of a progress bar's bar based on progress.
"""
function jobcolor(pbar::ProgressBar, job::ProgressJob)
    isnothing(job.N) && return "(255, 255, 255)"

    α = .8 * job.i/job.N
    β = max(sin(π * job.i/job.N) * .7, .4)

    c1, c2, c3 = pbar.colors
    r = string(int((.8 - α) * c1.r + β * c2.r + α * c3.r))
    g = string(int((.8 - α) * c1.g + β * c2.g + α * c3.g))
    b = string(int((.8 - α) * c1.b + β * c2.b + α * c3.b))
    return "(" * r * ", " * g * ", " * b * ")"
end

end
