# ---------------------------------------------------------------------------- #
#                                     HELP                                     #
# ---------------------------------------------------------------------------- #


# ---------------------------------------------------------------------------- #
#                               KEYBOARD CONTROLS                              #
# ---------------------------------------------------------------------------- #

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
struct Enter <: KeyInput end
struct SpaceBar <: KeyInput end
struct Esc <: KeyInput end
struct Del <: KeyInput end

KEYs = Dict{Int,KeyInput}(
    13 => Enter(),
    27 => Esc(),
    32 => SpaceBar(),
    127 => Del(),
    1000 => ArrowLeft(),
    1001 => ArrowRight(),
    1002 => ArrowUp(),
    1003 => ArrowDown(),
    1004 => DelKey(),
    1005 => HomeKey(),
    1006 => EndKey(),
    1007 => PageUpKey(),
    1008 => PageDownKey(),
)


catch_retval(retvals::Vector, retval) = push!(retvals, retval)
catch_retval(::Vector, ::Nothing) = return


function is_container(widget)::Bool
    wtype = typeof(widget)
    return hasfield(wtype, :widgets) && hasfield(wtype, :active)
end



"""
    keyboard_input(widget::AbstractWidget)

Read an user keyboard input during widget display.

If there are bytes available at `stdin`, read them.
If it's a special character (e.g. arrows) call `key_press`
for the `AbstractWidget` with the corresponding
`KeyInput` type. Else, if it's not `q` (reserved for exit),
use that.
If the input was `q` it signals that the display should be stopped
"""
function keyboard_input(widget)::Vector
    retvals = []
    if bytesavailable(terminal.in_stream) > 0
        # get input
        c = readkey(terminal.in_stream) 
        c = haskey(KEYs, Int(c)) ? KEYs[Int(c)] : Char(c)

        # execute command on each subwidget
        for wdg in PreOrderDFS(widget)
            controls = wdg.controls

            # for apps, only pass arguments to active widgets
            wtype = typeof(widget)
            if hasfield(wtype, :widgets) && hasfield(wtype, :active)
                
                active = widget.widgets[widget.active]
                childs = children(active)


                (wdg ∈ [widget, active] || wdg ∈ childs)  || continue
            end

            # see if a control has been defined for this key
            haskey(controls, c) && catch_retval(retvals, controls[c](wdg, c))

            # see if we can just pass any character
            c isa Char && haskey(controls, Char) && catch_retval(retvals, controls[Char](wdg, c))

            # see if a fallback option is available
            haskey(controls, :setactive) && catch_retval(retvals, controls[:setactive](wdg, c))
        end
    end
    return retvals
end


controls_union = Union{KeyInput, Char}