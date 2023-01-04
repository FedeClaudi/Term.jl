
abstract type AbstractLiveDisplay end

# ---------------------------------------------------------------------------- #
#                                LIVE INTERNALS                                #
# ---------------------------------------------------------------------------- #
@with_repr mutable struct LiveInternals
    iob::IOBuffer
    ioc::IOContext
    term::AbstractTerminal
    prevcontent::Union{Nothing, AbstractRenderable}
    prevcontentlines::Vector{String}
    raw_mode_enabled::Bool
    last_update::Union{Nothing, Int}
    refresh_Δt::Int

    function LiveInternals(; refresh_rate::Int=100)
        # get output buffers
        iob = IOBuffer()
        ioc = IOContext(iob, :displaysize=>displaysize(stdout))

        # prepare terminal 
        raw_mode_enabled = try
            raw!(terminal, true)
            true
        catch err
            @debug "Unable to enter raw mode: " exception=(err, catch_backtrace())
            false
        end

        # hide the cursor
        raw_mode_enabled && print(terminal.out_stream, "\x1b[?25l")

        return new(iob, ioc,  terminal, nothing, String[], raw_mode_enabled, nothing, (Int ∘ round)(1000/refresh_rate))
    end
end


# ---------------------------------------------------------------------------- #
#                                METHODS ON LIVE                               #
# ---------------------------------------------------------------------------- #
"""
Get the current conttent of a live display
"""
frame(::AbstractLiveDisplay) = error("Not implemented")

key_press(::AbstractLiveDisplay, ::Any) = nothing

function shouldupdate(live::AbstractLiveDisplay)::Bool
    currtime = Dates.value(now())
    isnothing(live.internals.last_update) && begin
        live.internals.last_update = currtime
        return true
    end

    Δt = currtime - live.internals.last_update
    if Δt > live.internals.refresh_Δt
        live.internals.last_update = currtime
        return true
    end
    return false
end

function replace_line(internals::LiveInternals)
    erase_line(internals.ioc)
    down(internals.ioc)
end

function replace_line(internals::LiveInternals, newline)
    erase_line(internals.ioc)
    println(internals.ioc, newline)
end

function read_stdout_output(internals::LiveInternals)
    write(internals.ioc, internals.pipe)
    out = String(take!(internals.ioc))
    length(out) > 0 ? out : nothing
end

function refresh!(live::AbstractLiveDisplay)::Bool
    # check for keyboard inputs
    shouldstop = keyboard_input(live)
    shouldstop && return false

    # check if its time to update
    shouldupdate(live) || return true

    # get new content
    internals = live.internals
    content::AbstractRenderable = frame(live)
    content_lines::Vector{String} = split(string(content), "\n")
    nlines::Int = length(content_lines)
    nlines_prev::Int = isnothing(internals.prevcontentlines) ? 1 : length(internals.prevcontentlines)+1

    # get calls to print from user
    # printed = read_stdout_output(live.internals)
    # isnothing(printed) || (scontent = printed / scontent)

    # remove extra lines from previous content
    up(internals.ioc, nlines_prev)
    for _ in 1:(nlines_prev - nlines)
        replace_line(internals)
    end

    # render new content
    for i in 1:nlines
        # (nlines_prev > 1 && content_lines[i] != internals.prevcontentlines[i]) && 
        !isnothing(internals.prevcontent) && content_lines[i] != internals.prevcontentlines[i] && begin
            down(internals.ioc)
            continue
        end
        replace_line(internals, content_lines[i])
    end

    # output
    internals.prevcontent = content
    internals.prevcontentlines = content_lines
    write(stdout, take!(internals.iob))
    return true
end

function erase!(live::AbstractLiveDisplay)
    nlines = live.internals.prevcontent.measure.h + 1
    up(live.internals.ioc, nlines)
    for _ in 1:nlines
        replace_line(live.internals)
    end
    write(stdout, take!(live.internals.iob))

    nothing
end

function stop!(live::AbstractLiveDisplay)
    internals = live.internals
    print(internals.term.out_stream, "\x1b[?25h") # unhide cursor
    raw!(internals.term, false)
    nothing
end

function play(live::AbstractLiveDisplay)
    while true
        refresh!(live) || break
    end
    stop!(live)
end
