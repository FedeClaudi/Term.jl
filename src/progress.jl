module progress

using Dates
import Parameters: @with_kw
import UUIDs: UUID

import Term: int, textlen, truncate, loop_last
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
        setwidth!.(job.columns, bcol_width)
    end

    # start job
    job.started = true
    job.startime = now()
    return nothing
end

function update!(job::ProgressJob; i = nothing)
    (!isnothing(job.N) && job.i >= job.N) && return stop!(job)
    job.i = isnothing(i) ? job.i + 1 : i
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
#                                  PROGRESS BAR                                #
# ---------------------------------------------------------------------------- #

Base.@kwdef mutable struct RenderStatus
    rendered::Bool = false
    nlines::Int = 0
    maxnlines::Int = 0
    hline::String = ""
end


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
    colors::Vector{RGBColor}
    Δt::Float64

    buff::IOBuffer  # will be used to store temporarily re-directed stdout
    running::Bool
    paused::Bool
    task::Union{Task, Nothing}
    renderstatus
end

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

function removejob!(pbar::ProgressBar, job::ProgressJob)
    pbar.paused = true
    stop!(job)
    deleteat!(pbar.jobs, findfirst(j -> j == job, pbar.jobs))
    pbar.paused = false
end

function getjob(pbar::ProgressBar, id)
    idx = findfirst(j -> j.id == id, pbar.jobs)
    isnothing(idx) && return nothing
    return pbar.jobs[idx]
end


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

function stop!(pbar::ProgressBar)
    pbar.paused = true
    pbar.running = false


    # if transient, delete 
    print("\n")
    if pbar.transient
        # move cursor to stale scrollregion and clear
        move_to_line(stdout, console_height())
        for i in 1:pbar.renderstatus.nlines+2
            erase_line(stdout)
            up(stdout)
        end
    end
    # restore scrollbar region
    change_scroll_region(stdout, console_height())
    show_cursor()

    return nothing
end

# --------------------------------- rendering -------------------------------- #
function render(job::ProgressJob, pbar::ProgressBar)::String
    color = jobcolor(pbar, job)
    return apply_style(join(update!.(job.columns, color), " "))
end

function render(job::ProgressJob)::String
    color = jobcolor(job)
    return apply_style(join(update!.(job.columns, color), " "))
end


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
        change_scroll_region(iob, height - njobs)

        pbar.renderstatus.rendered = true
        pbar.renderstatus.hline = string(
            hLine(pbar.width, "progress"; style="blue dim")
        )
        pbar.renderstatus.nlines = njobs
        pbar.renderstatus.maxnlines = njobs

    elseif njobs != pbar.renderstatus.nlines
        # if we need more lines, scroll
        if njobs > pbar.renderstatus.maxnlines
            print(iob, "\n"^(njobs - pbar.renderstatus.maxnlines - 1))
        end
        pbar.renderstatus.maxnlines = max(pbar.renderstatus.maxnlines, njobs)

        # move cursor to stale scrollregion and clear
        move_to_line(iob, height - pbar.renderstatus.nlines + 1)
        cleartoend(iob)
        change_scroll_region(iob, height)

        # create a new scrollregion
        change_scroll_region(iob, height - pbar.renderstatus.maxnlines)
        pbar.renderstatus.nlines = njobs
    end

    # move_to_line(iob, height - pbar.renderstatus.maxnlines)
    savecursor(iob)

    
    # move cursor to scrollregion and clear
    move_to_line(iob, height - pbar.renderstatus.maxnlines + 1)
    cleartoend(iob)

    # render the progressbars
    println(iob, pbar.renderstatus.hline)
    for (last, job) in loop_last(pbar.jobs)
        # job.finished && continue
        contents = render(job, pbar)
        coda = last ? "" : "\n"
        write(iob, contents * coda)
    end

    # restore position and write
    # move_to_line(iob, height - pbar.renderstatus.maxnlines - 1)
    restorecursor(iob)
    write(stdout, take!(iob))
    
    # nothing
end


# ---------------------------------------------------------------------------- #
#                                     WITH                                     #
# ---------------------------------------------------------------------------- #
function with(expr, pbar::ProgressBar)
    try
        start!(pbar)
        expr()
        render(pbar)
    finally
        stop!(pbar)
    end
end

# ---------------------------------------------------------------------------- #
#                                     TRACK                                    #
# ---------------------------------------------------------------------------- #
macro track(ex)
    iter = esc(ex.args[1].args[2])
    i = esc(ex.args[1].args[1])
    body = esc(ex.args[2])
    quote
        pbar = nothing
        try
            pbar = ProgressBar()
            start!(pbar)
            __pbarjob = addjob!(pbar; N=length($iter))
            for $i in $iter
                update!(__pbarjob) 
                $body
            end
            update!(__pbarjob)
            render(pbar)
        finally 
            stop!(pbar)
        end
        nothing
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
