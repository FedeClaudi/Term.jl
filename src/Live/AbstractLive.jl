
abstract type AbstractLiveDisplay end

# ---------------------------------------------------------------------------- #
#                                LIVE INTERNALS                                #
# ---------------------------------------------------------------------------- #
@with_repr mutable struct LiveInternals
    iob::IOBuffer
    ioc::IOContext
    term::AbstractTerminal
    prevcontent::Union{Nothing,AbstractRenderable}
    raw_mode_enabled::Bool
    last_update::Union{Nothing,Int}
    pipe::Union{Nothing,Pipe}
    original_stdout::Union{Nothing,Base.TTY}
    original_stderr::Union{Nothing,Base.TTY}
    redirected_stdout
    redirected_stderr

    function LiveInternals()
        # get output buffers
        iob = IOBuffer()
        ioc = IOContext(iob, :displaysize => displaysize(stdout))

        # prepare terminal 
        raw_mode_enabled = try
            raw!(terminal, true)
            true
        catch err
            @debug "Unable to enter raw mode: " exception = (err, catch_backtrace())
            false
        end

        # hide the cursor
        raw_mode_enabled && print(terminal.out_stream, "\x1b[?25l")

        # TODO add this to Console instead
        # replace stdout stderr
        default_stdout = stdout
        default_stderr = stderr

        # Redirect both the `stdout` and `stderr` streams to a single `Pipe` object.
        pipe = Pipe()
        Base.link_pipe!(pipe; reader_supports_async = true, writer_supports_async = true)
        @static if VERSION >= v"1.6.0-DEV.481" # https://github.com/JuliaLang/julia/pull/36688
            pe_stdout = IOContext(pipe.in, :displaysize=>displaysize(stdout))
            pe_stderr = IOContext(pipe.in, :displaysize=>displaysize(stdout))
        else
            pe_stdout = pipe.in
            pe_stderr = pipe.in
        end
        redirect_stdout(pe_stdout)
        redirect_stderr(pe_stderr)

        return new(
            iob,
            ioc,
            terminal,
            nothing,
            raw_mode_enabled,
            nothing,
            pipe,
            default_stdout,
            default_stderr,
            pe_stdout,
            pw_stderr,
        )
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
    if Δt > 5
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
    content::AbstractRenderable = frame(live)
    scontent = string(content)

    # get calls to print from user
    # printed = read_stdout_output(live.internals)
    # isnothing(printed) || (scontent = printed / scontent)

    # render
    internals = live.internals
    !isnothing(internals.prevcontent) && begin
        nlines = internals.prevcontent.measure.h + 1

        newlines = split(scontent, "\n")
        nnew = length(newlines)

        up(internals.ioc, nlines)
        for _ in 1:(nlines - nnew)
            replace_line(internals)
        end

        for i in 1:nnew
            replace_line(internals, newlines[i])
        end
    end

    if isnothing(internals.prevcontent)
        nlines = length(split(string(content), "\n"))
        print(internals.ioc, '\n'^nlines)
    end

    # output
    internals.prevcontent = content
    write(internals.original_stdout, take!(internals.iob))
    return true
end

function erase!(live::AbstractLiveDisplay)
    nlines = live.internals.prevcontent.measure.h + 1
    up(live.internals.ioc, nlines)
    for _ in 1:nlines
        replace_line(live.internals)
    end
    write(internals.original_stdout, take!(live.internals.iob))

    nothing
end

function stop!(live::AbstractLiveDisplay)
    internals = live.internals
    print(internals.term.out_stream, "\x1b[?25h") # unhide cursor
    raw!(internals.term, false)

    # reset original stdout

    redirect_stdout(internals.original_stdout)
    redirect_stderr(internals.original_stderr)
    close(internals.redirected_stdout)
    close(internals.redirected_stderr)
    # wait(internals.reading_task)
    nothing
end

function play(live::AbstractLiveDisplay)
    while true
        refresh!(live) || break
    end
    stop!(live)
end
