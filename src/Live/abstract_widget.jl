abstract type AbstractWidget end

# ---------------------------------------------------------------------------- #
#                                LIVE INTERNALS                                #
# ---------------------------------------------------------------------------- #
"""
struct LiveInternals
    iob::IOBuffer
    ioc::IOContext
    term::AbstractTerminal
    prevcontent::Union{Nothing, AbstractRenderable, String}
    prevcontentlines::Vector{String}
    raw_mode_enabled::Bool
    last_update::Union{Nothing, Int}
    refresh_Δt::Int
    help_shown::Bool
end

`LiveInternals` handles "under the hood" work for live widgets. 
It takes care of keeping track of information such as the content
displayed at the last refresh of the widget to inform the printing
of the widget's content at the next refresh.

LiveInternals also holds linked_widgets which can be used to link to 
other widgets to access their internal variables.
"""
@with_repr mutable struct LiveInternals
    iob::IOBuffer
    ioc::IOContext
    term::AbstractTerminal
    prevcontent::Union{Nothing, AbstractRenderable}
    prevcontentlines::Vector{String}
    raw_mode_enabled::Bool
    last_update::Union{Nothing, Int}
    refresh_Δt::Int
    help_shown::Bool
    help_message::Union{Nothing, String}
    should_stop::Bool

    function LiveInternals(; refresh_rate::Int=60, help_message=nothing)
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
        return new(iob, ioc,  terminal, nothing, String[], raw_mode_enabled, nothing, (Int ∘ round)(1000/refresh_rate), false, help_message, false,)
    end
end

# ---------------------------------------------------------------------------- #
#                                ABSTRACT WIDGET                               #
# ---------------------------------------------------------------------------- #


"""
Get the current conttent of a live display
"""
frame(::AbstractWidget) = error("Not implemented")

"""
    keypress

Capture user input during live widgets display.
"""
function keypress end

key_press(::AbstractWidget, ::KeyInput) = nothing

"""
- {bold white}enter, esc{/bold white}: quit program, possibly returning a value
"""
function key_press(live::AbstractWidget, ::Enter) 
    live.internals.should_stop = true
    return nothing
end

function key_press(live::AbstractWidget, ::Esc) 
    live.internals.should_stop = true
    return nothing
end

"""
- {bold white}q{/bold white}: quit program without returning anything

- {bold white}h{/bold white}: toggle help message display
"""
function key_press(live::AbstractWidget, c::Char)::Tuple{Bool, Nothing}
    c == 'q' && return (true, nothing)
    c == 'h' && begin
    toggle_help(live)
        return (false, nothing)
    end
    return (false, nothing)
end


"""
    shouldupdate(live::AbstractWidget)::Bool

Check if a widget's display should be updated based on:
    1. enough time elapsed since last update
    2. the widget has not beed displayed het
"""
function shouldupdate(live::AbstractWidget)::Bool
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

"""
    replace_line(internals::LiveInternals)

Erase a line and move cursor
"""
function replace_line(internals::LiveInternals)
    erase_line(internals.ioc)
    down(internals.ioc)
end

"""
    replace_line(internals::LiveInternals, newline)

Erase a line, write new content and move cursor. 
"""
function replace_line(internals::LiveInternals, newline)
    erase_line(internals.ioc)
    println(internals.ioc, newline)
end


# function read_stdout_output(internals::LiveInternals)
#     write(internals.ioc, internals.pipe)
#     out = String(take!(internals.ioc))
#     length(out) > 0 ? out : nothing
# end


"""
    refresh!(live::AbstractWidget)::Tuple{Bool, Any}

Update the terminal display of a widget.

this is done by calling `frame` on the widget to get the new content.
Then, line by line, the new content is compared to the previous one and when
a discrepancy occurs the lines gets re-written. 
This is all done printing to a buffer first and then to `stdout` to avoid
jitter.
"""
function refresh!(live::AbstractWidget)::Tuple{Bool, Any}
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

"""
    erase!(live::AbstractWidget)

Erase a widget from the terminal.
"""
function erase!(live::AbstractWidget)
    isnothing(live.internals.prevcontent) && return

    nlines = live.internals.prevcontent.measure.h
    up(live.internals.ioc, nlines)
    cleartoend(live.internals.ioc)
    write(stdout, take!(live.internals.iob))
    nothing
end

"""
    stop!(live::AbstractWidget)

Restore normal terminal behavior.
"""
function stop!(live::AbstractWidget)
    Base.stop_reading(stdin)

    internals = live.internals
    print(internals.term.out_stream, "\x1b[?25h") # unhide cursor
    raw!(internals.term, false)
    nothing
end


"""
    play(live::AbstractWidget; transient::Bool=true)

Keep refreshing a renderable, until the user interrupts it. 
"""
function play(live::AbstractWidget; transient::Bool=true)
    Base.start_reading(stdin)

    retval = nothing
    while true
        should_continue, retval = refresh!(live) 
        should_continue || break
    end
    stop!(live)
    transient && erase!(live)
    return retval
end
