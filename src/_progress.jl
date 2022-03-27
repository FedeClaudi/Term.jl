
"""
Definition of several type of columns for progress bars.
Used in progress.jl.
"""

# ---------------------------------------------------------------------------- #
#                                    columns                                   #
# ---------------------------------------------------------------------------- #
abstract type AbstractColumn <: AbstractRenderable end


# ------------------------------- text columns ------------------------------- #
# ---------------------------- description column ---------------------------- #
mutable struct DescriptionColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    text::String

    function DescriptionColumn(job::ProgressJob)
        seg = Segment(job.description)
        new(job, [seg], seg.measure, seg.text)
    end
end

update!(col::DescriptionColumn, args...)::String = col.text


# ----------------------------- separator column ----------------------------- #
struct SeparatorColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    text::String

    function SeparatorColumn(job::ProgressJob)
        seg = Segment("●", pink)
        return new(job, [seg], seg.measure, seg.text)
    end
end

update!(col::SeparatorColumn, args...)::String = col.text


# ----------------------------- completed column ----------------------------- #
struct CompletedColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    text::String
    padwidth::Int

    function CompletedColumn(job::ProgressJob)
        if isnothing(job.N)
            seg = Segment(" "^10)
            return new(job, [seg], seg.measure, "", 0)
        else
            width = length(string(N))*2+1
            seg = Segment(" "^width)
            text = apply_style("[white bold]/[/white bold][(.1, .8, .4) underline]$N[/(.1, .8, .4) underline]")
            return new(job, [seg], seg.measure, text, length(digits(N)))
        end
    end
end


function update!(col::CompletedColumn, color::String, args...)::String
    isnothing(job.N) && return apply_style(string(job.i), color*" bold")
    return apply_style(lpad(string(job.i), col.padwidth), color*" bold")
end


# ----------------------------- percentage column ---------------------------- #
struct PercentageColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    padwidth::Int

    function PercentageColumn(job::ProgressJob)
        seg = Segment(" "^5) # "xxx %
        return new(job, [seg], seg.measure, seg.measure.w-2)
    end
    
end

function update!(col::PercentageColumn, args...)::String
    isnothing(job.N) && return ""
    p = string(int(job.i / job.N * 100))
    p = lpad(p, col.padwidth)
    return "\e[2m"*p*" %\e[0m"
end

# -------------------------------- bar column -------------------------------- #
mutable struct ProgressColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    nsegs::Int
    is_spinner::Bool

    ProgressColumn(job::ProgressJob) = new(job, Vector{Segment}(), Measure(0, 0), 0, isnothing(job.N))
end

function setwidth!(col::ProgressColumn, width::Int)
    col.measure = Measure(width, 1)
    col.nsegs = width
end

function update!(col::ProgressColumn, color::String, args...)::String
    if col.is_spinner
        # TODO update as spinner
        return "make spinner"
    else
        completed = int(col.nsegs * job.i/job.N)
        remaining = col.nsegs - completed

        completed = completed < 0 ? 0 : completed
        remaining = remaining < 0 ? 0 : remaining

        return apply_style("[" *color*" bold]" * '━'^(completed) * "[/"*color*" bold]"* " "^(remaining))
    end
end


# ------------------------------ elapsed column ------------------------------ #

struct ElapsedColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    style::String
    padwidth::Int
    
    ElapsedColumn(job::ProgressJob) = new(job, [], Measure(6+9, 1), style, 6)

end


function update!(col::ElapsedColumn, args...)::String
    isnothing(job.starttime) && return " "^(col.measure.w)
    elapsedtime = (now() - job.starttime).value  # in ms

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

    msg = lpad(truncate(msg, col.padwidth), col.padwidth)
    return apply_style("elapsed: $(msg)", col.style)
end


# -------------------------------- ETA column -------------------------------- #

struct ETAColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    style::String
    padwidth::Int

    ETAColumn(job::ProgressJob; style=teal) = new(job, [], Measure(7+11, 1), style, 7)

end



function update!(col::ETAColumn, args...)::String
    isnothing(job.starttime) && return " "^(col.measure.w)

    # get remaining time in ms
    elapsed = (now() - job.starttime).value  # in ms
    perc = job.i/job.N
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

    msg = lpad(truncate(msg, col.padwidth), col.padwidth)

    return apply_style("remaining: $(msg)", col.style)
end




# ---------------------------------------------------------------------------- #
#                                COLUMNS PRESETS                               #
# ---------------------------------------------------------------------------- #

function get_columns(columnsset::Symbol)::Vector{DataType}
    if columnsset == :minimal
        return [
            DescriptionColumn,
            ProgressColumn,
        ]
    elseif columnsset == :default
        return [
            DescriptionColumn,
            SeparatorColumn,
            ProgressColumn,
            SeparatorColumn,
            CompletedColumn,
            PercentageColumn,
        ]
    else
        # extensive
        return [
            DescriptionColumn,
            SeparatorColumn,
            ProgressColumn,
            SeparatorColumn,
            CompletedColumn,
            PercentageColumn,
            SeparatorColumn,
            ElapsedColumn,
            ETAColumn
        ]
    end
end

