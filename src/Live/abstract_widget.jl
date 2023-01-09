
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
    prevcontent::Union{Nothing,AbstractRenderable}
    prevcontentlines::Vector{String}
    raw_mode_enabled::Bool
    last_update::Union{Nothing,Int}
    refresh_Δt::Int
    help_shown::Bool
    help_message::Union{Nothing,String}
    should_stop::Bool

    function LiveInternals(; refresh_rate::Int = 60, help_message = nothing)
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
        return new(
            iob,
            ioc,
            terminal,
            nothing,
            String[],
            raw_mode_enabled,
            nothing,
            (Int ∘ round)(1000 / refresh_rate),
            false,
            help_message,
            false,
        )
    end
end

# ---------------------------------------------------------------------------- #
#                                ABSTRACT WIDGET                               #
# ---------------------------------------------------------------------------- #

"""
    AbstractWidget

Abstract widgets must have four obligatory fields:

    internals::LiveInternals
    measure::Measure
    controls:: Dict{Union{KeyInput, Char}, Function}
    parent::Union{Nothing, AbstractWidget}

and one optional one
    on_draw::Union{Nothing, Function} = nothing
"""
abstract type AbstractWidget end

# ----------------------------- widget functions ----------------------------- #

get_active(::AbstractWidget) = nothing

function isactive(widget::AbstractWidget)
    par = AbstractTrees.parent(widget)
    isnothing(par) && return true
    return widget == get_active(par) && isactive(par)
end


quit(widget::AbstractWidget, ::Any) = quit(widget)

function quit(widget::AbstractWidget)
    widget.internals.should_stop = true
    par = AbstractTrees.parent(widget)
    isnothing(par) || quit(par)
    return nothing
end



"""
Get the current conttent of a widget
"""
frame(::AbstractWidget) = error("Not implemented")


# ------------------------------ tree structure ------------------------------ #
function AbstractTrees.children(widget::AbstractWidget) 
    hasfield(typeof(widget), :widgets) || return []
    widget.widgets isa AbstractDict && return collect(values(widget.widgets))
    return widget.widgets
end

function AbstractTrees.parent(widget::AbstractWidget)
    return widget.parent
end

function print_node(io, x) 
    color = isactive(x) ? "green" : "dim red"
    tprint(
          io, "{$color}$(typeof(x)){/$color}")
end


Base.print(io::IO, widget::AbstractWidget) = print_tree(print_node, io, widget)


# ---------------------------------------------------------------------------- #
#                                   RENDERING                                  #
# ---------------------------------------------------------------------------- #

"""
    shouldupdate(widget::AbstractWidget)::Bool

Check if a widget's display should be updated based on:
    1. enough time elapsed since last update
    2. the widget has not beed displayed het
"""
function shouldupdate(widget::AbstractWidget)::Bool
    currtime = Dates.value(now())
    isnothing(widget.internals.last_update) && begin
        widget.internals.last_update = currtime
        return true
    end

    Δt = currtime - widget.internals.last_update
    if Δt > widget.internals.refresh_Δt
        widget.internals.last_update = currtime
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


function add_debugging_info!(content::AbstractRenderable, widget::AbstractWidget)::AbstractRenderable
    tree = sprint(print, widget)

    debug_info = Panel(
        tree;
        width = content.measure.w,
    )
    return debug_info / content
end


"""
    refresh!(live::AbstractWidget)::Tuple{Bool, Any}

Update the terminal display of a widget.

this is done by calling `frame` on the widget to get the new content.
Then, line by line, the new content is compared to the previous one and when
a discrepancy occurs the lines gets re-written. 
This is all done printing to a buffer first and then to `stdout` to avoid
jitter.
"""
function refresh!(widget::AbstractWidget)
    # check for keyboard inputs
    retval = keyboard_input(widget)
    widget.internals.should_stop && return something(retval, [])

    # check if its time to update
    shouldupdate(widget) || return nothing

    # get new content
    internals = widget.internals
    content::AbstractRenderable = frame(widget)

    LIVE_DEBUG[] == true && begin
        content = add_debugging_info!(content, widget)
    end

    content_lines::Vector{String} = split(string(content), "\n")
    nlines::Int = length(content_lines)
    nlines_prev::Int =
        isnothing(internals.prevcontentlines) ? 0 : length(internals.prevcontentlines)
    old_lines = internals.prevcontentlines
    nlines_prev == 0 && print(internals.ioc, "\n")

    # render new content
    up(internals.ioc, nlines_prev)
    for i in 1:nlines
        line = content_lines[i]

        # avoid re-writing unchanged lines
        !isnothing(internals.prevcontent) &&
            nlines_prev > i &&
            begin
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
    return nothing
end

"""
    erase!(widget::AbstractWidget)

Erase a widget from the terminal.
"""
function erase!(widget::AbstractWidget)
    isnothing(widget.internals.prevcontent) && return

    nlines = widget.internals.prevcontent.measure.h
    up(widget.internals.ioc, nlines)
    cleartoend(widget.internals.ioc)
    write(stdout, take!(widget.internals.iob))
    nothing
end

"""
    stop!(widget::AbstractWidget)

Restore normal terminal behavior.
"""
function stop!(widget::AbstractWidget)
    Base.stop_reading(stdin)

    internals = widget.internals
    print(internals.term.out_stream, "\x1b[?25h") # unhide cursor
    print(stdout, "\x1b[?25h")
    raw!(internals.term, false)
    nothing
end

"""
    play(widget::AbstractWidget; transient::Bool=true)

Keep refreshing a renderable, until the user interrupts it. 
"""
function play(widget::AbstractWidget; transient::Bool = true)
    Base.start_reading(stdin)

    retval = nothing
    while isnothing(retval)
        retval = refresh!(widget)
    end
    stop!(widget)
    transient && erase!(widget)
    return retval
end






