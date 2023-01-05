
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
struct CharKey <: KeyInput
    char::Char
end

KEYs = Dict{Int,KeyInput}(
    13 => Enter(),
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


function help(live::AbstractLiveDisplay)
    internals = live.internals

    # make help message
    key_methods = methods(key_press, (typeof(live), KeyInput))
    # help_message = RenderableText(join(string.(key_methods), "\n"))

    messages =  [
        RenderableText(md"#### Live Renderable description"; width=live.measure.w-10),
        RenderableText(getdocs(live); width=live.measure.w-10),
        RenderableText(md"#### Controls"; width=live.measure.w-10),

        # RenderableText(
        #     @doc(key_press(live)); width=live.measure.w-10
        # ),
        ]



    # for m in key_methods
    #     push!(
    #         messages,
    #         RenderableText(getdocs(eval(m.name)); width=live.measure.w-10)
    #     )
    # end



    help_message = Panel(
        messages; 
        width=live.measure.w,
        title="$(typeof(live)) help",
        title_style="bold",
        title_justify=:center,
        style="dim",
        )


    # show/hide message
    if internals.help_shown
        # hide it
        internals.help_shown = false

        # go to the top of the error message and delete everything
        h = console_height() - length(internals.prevcontentlines) - help_message.measure.h - 1
        move_to_line(stdout, h)
        cleartoend(stdout)

        # move cursor back to the top of the live to re-print it in the right position
        move_to_line(stdout, console_height() - length(internals.prevcontentlines))
    else
        # show it
        erase!(live)
        println(stdout, help_message)
        internals.help_shown = true
    end

    internals.prevcontent = nothing
    internals.prevcontentlines = String[]
end


"""
    keyboard_input(live::AbstractLiveDisplay)

Read an user keyboard input during live display.

If there are bytes available at `stdin`, read them.
If it's a special character (e.g. arrows) call `key_press`
for the `AbstractLiveDisplay` with the corresponding
`KeyInput` type. Else, if it's not `q` (reserved for exit),
use that.
If the input was `q` it signals that the display should be stopped
"""
function keyboard_input(live::AbstractLiveDisplay)::Tuple{Bool, Any}
    if bytesavailable(terminal.in_stream) > 0
        c = readkey(terminal.in_stream) |> Int

        c in keys(KEYs) && begin
            key = KEYs[Int(c)]    
            retval = key_press(live, key)
            return (key isa Enter, retval)
        end


        c = Char(c)
        c == 'q' && return (true, nothing)

        c == 'h' && begin
            help(live)
            return (false, nothing)
        end
        key_press(live, CharKey(c))
    end
    return (false, nothing)
end
