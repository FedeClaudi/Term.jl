import MyterialColors: orange_light, teal, purple_light, pink

"""
Definition of several type of columns for progress bars.
Used in progress.jl.
"""

# ---------------------------------------------------------------------------- #
#                                    columns                                   #
# ---------------------------------------------------------------------------- #
abstract type AbstractColumn <: AbstractRenderable end

setwidth!(col::AbstractColumn, width::Int) = nothing

# ---------------------------------------------------------------------------- #
#                                 TEXT COLUMNS                                 #
# ---------------------------------------------------------------------------- #
# ---------------------------- description column ---------------------------- #
mutable struct DescriptionColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    text::String

    function DescriptionColumn(job::ProgressJob; style::String = orange_light)
        seg = Segment(job.description, style)
        return new(job, [seg], seg.measure, seg.text)
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
        return new(job, [seg], Measure(1, 1), seg.text)
    end
end

update!(col::SeparatorColumn, args...)::String = col.text

struct SpaceColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    text::String

    function SpaceColumn(job::ProgressJob; width = 1)
        seg = Segment(" "^width, pink)
        return new(job, [seg], seg.measure, seg.text)
    end
end

update!(col::SpaceColumn, args...)::String = col.text

# ----------------------------- completed column ----------------------------- #
struct CompletedColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    text::String
    padwidth::Int
    style::String

    function CompletedColumn(job::ProgressJob; style::String = "white bold")
        if isnothing(job.N)
            seg = Segment(" "^10)
            return new(job, [seg], seg.measure, "", 0, style)
        else
            width = length(string(job.N)) * 2 + 1
            seg = Segment(" "^width)
            text = apply_style(
                "{white bold}/{/white bold}{(.1, .8, .4) underline}$(job.N){/(.1, .8, .4) underline}",
            )
            return new(job, [seg], seg.measure, text, length(digits(job.N)), style)
        end
    end
end

function update!(col::CompletedColumn, color::String, args...)::String
    isnothing(col.job.N) && return apply_style(string(col.job.i), col.style)
    return apply_style(lpad(string(col.job.i), col.padwidth) * col.text, color * " bold")
end

# ----------------------------- percentage column ---------------------------- #
struct PercentageColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure

    function PercentageColumn(job::ProgressJob)
        seg = Segment(" "^4) # "xxx %
        return new(job, [seg], seg.measure)
    end
end

function update!(col::PercentageColumn, args...)::String
    isnothing(col.job.N) && return ""
    frac = int(col.job.i / col.job.N * 100)
    p = string(frac)
    p = frac == 100 ? p : lpad(p, 3)
    return "\e[2m" * p * "%\e[0m"
end

# ----------------------------- downloaded column ---------------------------- #
struct DownloadedColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    tot_size::String

    function DownloadedColumn(job::ProgressJob)
        tot_size = get_file_format(job.N)
        seg = Segment(" "^(length(tot_size) * 2 + 1))
        return new(job, [seg], seg.measure, tot_size)
    end
end

function update!(col::DownloadedColumn, args...)::String
    isnothing(col.job.N) && return ""
    completed = get_file_format(col.job.i)

    return lpad(completed * "/" * col.tot_size, col.measure.w)
end

# ---------------------------------------------------------------------------- #
#                                TIMING COLUMNS                                #
# ---------------------------------------------------------------------------- #
# ------------------------------ elapsed column ------------------------------ #

struct ElapsedColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    style::String
    padwidth::Int

    function ElapsedColumn(job::ProgressJob; style = purple_light)
        return new(job, [], Measure(6 + 9, 1), style, 6)
    end
end

function update!(col::ElapsedColumn, args...)::String
    isnothing(col.job.startime) && return " "^(col.measure.w)
    elapsedtime = (now() - col.job.startime).value  # in ms

    # format elapsed message
    if elapsedtime < 1000
        msg = "$(elapsedtime)ms"
    elseif elapsedtime < (60 * 1000)
        # under a minute
        elapsed = round(elapsedtime / 1000; digits = 2)
        msg = "$(elapsed)s"
    else
        # show minutes
        elapsed = round(elapsedtime / (60 * 1000); digits = 2)
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

    ETAColumn(job::ProgressJob; style = teal) = new(job, [], Measure(7 + 11, 1), style, 7)
end

function update!(col::ETAColumn, args...)::String
    isnothing(col.job.startime) && return " "^(col.measure.w)
    isnothing(col.job.N) && return " "^(col.measure.w)

    # get remaining time in ms
    elapsed = (now() - col.job.startime).value  # in ms
    perc = col.job.i / col.job.N
    remaining = elapsed * (1 - perc) / perc

    # format elapsed message
    if remaining < 1000
        msg = "$(round(remaining; digits=0))ms"
    elseif remaining < (60 * 1000)
        # under a minute
        remaining = round(remaining / 1000; digits = 2)
        msg = "$(remaining)s"
    else
        # show minutes
        remaining = round(remaining / (60 * 1000); digits = 2)
        msg = "$(remaining)min"
    end

    msg = lpad(truncate(msg, col.padwidth), col.padwidth)

    return apply_style("remaining: $(msg)", col.style)
end

# ---------------------------------------------------------------------------- #
#                               PROGRESS COLUMNS                               #
# ---------------------------------------------------------------------------- #

# ------------------------------ progress column ----------------------------- #
mutable struct ProgressColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    nsegs::Int

    ProgressColumn(job::ProgressJob) = new(job, Vector{Segment}(), Measure(0, 0), 0)
end

function setwidth!(col::ProgressColumn, width::Int)
    col.measure = Measure(width, 1)
    return col.nsegs = width
end

function update!(col::ProgressColumn, color::String, args...)::String
    completed = int(col.nsegs * col.job.i / col.job.N)
    remaining = col.nsegs - completed
    return apply_style(
        "{" * color * " bold}" * '━'^(completed) * "{/" * color * " bold}" * " "^(remaining)
    )
end

# ------------------------------ spinner columns ----------------------------- #

SPINNERS = Dict(
    :dot => Dict(
        "period" => 100,
        "frames" => [
            "( ●    )",
            "(  ●   )",
            "(   ●  )",
            "(    ● )",
            "(     ●)",
            "(    ● )",
            "(   ●  )",
            "(  ●   )",
            "( ●    )",
            "(●     )",
        ],
    ),
    :circle => Dict("period" => 125, "frames" => ["◐", "◓", "◑", "◒"]),
    :toggle => Dict("period" => 250, "frames" => ["⦾⦿", "⦿⦾"]),
    :toggle2 => Dict("period" => 250, "frames" => ["◯", "⬤"]),
    :bar => Dict(
        "period" => 100,
        "frames" => [
            "(=   )",
            "(==  )",
            "(=== )",
            "( ===)",
            "(  ==)",
            "(   =)",
            "(   =)",
            "(  ==)",
            "( ===)",
            "(====)",
            "(=== )",
            "(==  )",
            "(=   )",
        ],
    ),
    :greek => Dict("period" => 350, "frames" => ["ϴ", "Ω", "Φ", "Ο"]),
)

mutable struct SpinnerColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    frames::Vector{String}
    Δt::Float64                 # how frequently to update display, in milliseconds
    frameidx::Int
    nframes::Int
    lastupdated::Int
    lasttext::String

    function SpinnerColumn(
        job::ProgressJob; spinnertype::Symbol = :dot, style = "bold blue"
    )
        spinnerdata = copy(SPINNERS[spinnertype])

        spinnerdata["frames"] = map(
            frame -> apply_style(frame, style), spinnerdata["frames"]
        )

        seg = Segment(spinnerdata["frames"][1])

        return new(
            job,
            [seg],
            seg.measure,
            spinnerdata["frames"],
            spinnerdata["period"],
            1,
            length(spinnerdata["frames"]),
            0,
            spinnerdata["frames"][1],
        )
    end
end

function update!(col::SpinnerColumn, args...)::String
    col.job.started || return " "^(col.measure.w)
    col.job.finished && return "{green bold}✔{/green bold}"

    t = (now() - col.job.startime).value

    if t - col.lastupdated >= col.Δt
        col.lastupdated = t
        col.frameidx = col.frameidx == col.nframes ? 1 : col.frameidx + 1
        col.lasttext = col.frames[col.frameidx]
    end

    return col.lasttext
end

# ---------------------------------------------------------------------------- #
#                                COLUMNS PRESETS                               #
# ---------------------------------------------------------------------------- #

function get_columns(columnsset::Symbol)::Vector{DataType}
    if columnsset == :minimal
        return [DescriptionColumn, ProgressColumn]
    elseif columnsset == :default
        return [
            DescriptionColumn,
            SeparatorColumn,
            ProgressColumn,
            SeparatorColumn,
            CompletedColumn,
            PercentageColumn,
        ]
    elseif columnsset == :spinner
        return [DescriptionColumn, SpaceColumn, SpinnerColumn, SpaceColumn, CompletedColumn]
    elseif columnsset == :detailed
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
            ETAColumn,
        ]
    else
        @warn "Columns name not recognized: $columnsset"
        return get_columns(:minimal)
    end
end
