
abstract type AbstractLiveDisplay end

# ---------------------------------------------------------------------------- #
#                                LIVE INTERNALS                                #
# ---------------------------------------------------------------------------- #
@with_repr mutable struct LiveInternals
    iob::IOBuffer
    ioc::IOContext
    term::AbstractTerminal
    prevcontent::Union{Nothing, AbstractRenderable, String}
    prevcontentlines::Vector{String}
    raw_mode_enabled::Bool
    last_update::Union{Nothing, Int}
    refresh_Δt::Int
    help_shown::Bool

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

        return new(iob, ioc,  terminal, nothing, String[], raw_mode_enabled, nothing, (Int ∘ round)(1000/refresh_rate), false)
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

"""
CharKey('q'): quit program without returning anything
CharKey('h'): toggle help message display
"""
function key_press(live::AbstractLiveDisplay, k::CharKey)::Tuple{Bool, Nothing}
    k.char == 'q' && return (true, nothing)
    k.char == 'h' && begin
        help(live)
        return (false, nothing)
    end
    return (false, nothing)
end


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

function refresh!(live::AbstractLiveDisplay)::Tuple{Bool, Any}
    # check for keyboard inputs
    shouldstop, retval = keyboard_input(live)
    shouldstop && return (false, retval)

    # check if its time to update
    shouldupdate(live) || return (true, retval)

    # get new content
    internals = live.internals
    content::Union{String, AbstractRenderable} = frame(live)
    content_lines::Vector{String} = split(string(content), "\n")
    nlines::Int = length(content_lines)
    nlines_prev::Int = isnothing(internals.prevcontentlines) ? 0 : length(internals.prevcontentlines)
    old_lines = internals.prevcontentlines
    nlines_prev == 0 && print(internals.ioc, "\n")

    # get calls to print from user
    # printed = read_stdout_output(live.internals)
    # isnothing(printed) || (scontent = printed / scontent)

    # render new content
    up(internals.ioc, nlines_prev)
    for i in 1:nlines
        line = content_lines[i]
        
        # avoid re-writing unchanged lines
        !isnothing(internals.prevcontent) && nlines_prev > i && begin
            old_line = old_lines[i]
            line == old_line && begin
                down(internals.ioc)
                continue
            end
        end

        # re-write line
        replace_line(internals, line)
    end

    # output
    internals.prevcontent = content
    internals.prevcontentlines = content_lines
    write(stdout, take!(internals.iob))
    return (true, retval)
end

function erase!(live::AbstractLiveDisplay)
    nlines = live.internals.prevcontent.measure.h
    up(live.internals.ioc, nlines)
    cleartoend(live.internals.ioc)
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
    retval = nothing
    while true
        should_continue, retval = refresh!(live) 
        should_continue || break
    end
    stop!(live)
    return retval
end
