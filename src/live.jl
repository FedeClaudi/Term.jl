using REPL
using REPL.TerminalMenus: readkey, terminal
using REPL.Terminals: raw!, AbstractTerminal
using Dates


using Term
using Term.Consoles
import Term.Renderables: AbstractRenderable


@enum(Key,
    ARROW_LEFT = 1000,
    ARROW_RIGHT,
    ARROW_UP,
    ARROW_DOWN,
    DEL_KEY,
    HOME_KEY,
    END_KEY,
    PAGE_UP,
    PAGE_DOWN)




abstract type KeyInput end
struct ArrowLeft <: KeyInput end
struct ArrowRight <: KeyInput end
struct ArrowUp <: KeyInput end
struct ArrowDown <: KeyInput end
struct DelKey <: KeyInput end
struct HomeKey <: KeyInput end
struct EndKey <: KeyInput end
struct PageUpKey <: KeyInput end
struct PageDownKey <: KeyInput end


KEYs = Dict{Int, KeyInput}(
    1000=>ArrowLeft(),
    1001=>ArrowRight(),
    1002=>ArrowUp(),
    1003=>ArrowDown(),
    1004=>DelKey(),
    1005=>HomeKey(),
    1006=>EndKey(),
    1007=>PageUpKey(),
    1008=>PageDownKey(),
)






# ---------------------------------------------------------------------------- #
#                                 ABSTRACT LIVE                                #
# ---------------------------------------------------------------------------- #

abstract type AbstractLiveDisplay end

"""
Update a live renderable's content
"""
update!(::AbstractLiveDisplay, ::AbstractRenderable) = error("Not implemented")

"""
Get the current conttent of a live display
"""
frame(::AbstractLiveDisplay) = error("Not implemented")

key_press(live::AbstractLiveDisplay, inpt::KeyInput) = begin
    @warn "Key press for $inpt not implemented for $(typeof(live))"
    return false
end



# ------------------------------ keyboard input ------------------------------ #
function keyboard_input(live::AbstractLiveDisplay)
    if bytesavailable(terminal.in_stream) > 0
        c = readkey(terminal.in_stream) |> Int
        return if Int(c) in keys(KEYs)
            out = key_press(live, KEYs[Int(c)])
            out isa Bool && return out
            return true
        else
            c = Char(c)
            return if c == 'q'
                c
            else
                true
            end
        end
    end
    return true
end


# ---------------------------------- update ---------------------------------- #

function shouldupdate(live::AbstractLiveDisplay)::Bool
    return true
    currtime = Dates.value(now())
    isnothing(live.internals.last_update) && begin
        live.internals.last_update = currtime
        return true
    end
    
    Δt = currtime - live.internals.last_update
    if Δt > 10
        live.internals.last_update = currtime
        return true
    end
    return false
end

function update!(live::AbstractLiveDisplay)::Bool
    # check for keyboard inputs
    inp = keyboard_input(live)
    inp == 'q' && return false

    shouldupdate(live) || return true

    # get new content
    content::AbstractRenderable = frame(live)

    # render
    internals = live.internals
    !isnothing(internals.prevcontent) && inp && begin
        nlines = internals.prevcontent.measure.h + 1
        for _ in 1:nlines
            up(internals.ioc)
            erase_line(internals.ioc)
        end
    end

    println(internals.ioc, content)
    internals.prevcontent = content

    write(stdout, take!(internals.iob))
    return true
end


# ----------------------------------- stop ----------------------------------- #
function stop!(live::AbstractLiveDisplay)
    print(live.internals.term.out_stream, "\x1b[?25h") # unhide cursor
    raw!(live.internals.term, false)
    nothing
end


