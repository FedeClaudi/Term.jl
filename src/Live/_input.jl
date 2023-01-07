
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

"""
toggle_help(live::AbstractWidget; help_widget::Union{Nothing, AbstractWidget}=nothing)

Toggle help tooltip display for a widget widget.

By default the help message of `live` is shown, but for "nested" widgets one can 
directly specify for which widget to look up the help message for with `help_widget`.

The help message itself is made up of the docstring for the `live` struct and the docstrings
of all methods for `key_press(typeof(live), ::Any)`.
"""
function toggle_help(live; help_widget = nothing)
    internals = live.internals
    help_widget = something(help_widget, live)

    # get the docstring for each key_press method for the widget
    key_methods = methods(key_press, (typeof(help_widget), LiveWidgets.KeyInput))

    dcs = Docs.meta(LiveWidgets)
    bd = Base.Docs.Binding(LiveWidgets, :key_press)

    added_sigs = []
    function get_method_docstring(m)
        try
            sig = m.sig.types[3]
            sig ∈ added_sigs && return ""
            docstr = dcs[bd].docs[Tuple{m.sig.types[2],m.sig.types[3]}].text[1]
            push!(added_sigs, sig)
            return docstr
        catch
            return ""
        end
    end

    width = console_width()
    methods_docs =
        map(m -> RenderableText(get_method_docstring(m); width = width - 10), key_methods)

    # compose help tooltip
    docstring = RenderableText(getdocs(help_widget); width = width - 10)
    help_message =
        isnothing(help_widget.internals.help_message) ? docstring :
        docstring / RenderableText(help_widget.internals.help_message; width = width - 10)

    messages = [
        RenderableText(md"#### Widget description"; width = width - 10),
        help_message,
        "",
        RenderableText(md"#### Controls "; width = width - 10),
        methods_docs...,
    ]

    # create full message
    help_message = Panel(
        messages;
        width = width,
        title = "$(typeof(help_widget)) help",
        title_style = "default bold blue",
        title_justify = :center,
        style = "dim",
    )

    # show/hide message
    if internals.help_shown
        # hide it
        internals.help_shown = false

        # go to the top of the error message and delete everything
        h =
            console_height() - length(internals.prevcontentlines) - help_message.measure.h -
            1
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
    keyboard_input(live::AbstractWidget)

Read an user keyboard input during live display.

If there are bytes available at `stdin`, read them.
If it's a special character (e.g. arrows) call `key_press`
for the `AbstractWidget` with the corresponding
`KeyInput` type. Else, if it's not `q` (reserved for exit),
use that.
If the input was `q` it signals that the display should be stopped
"""
function keyboard_input(live)::Tuple{Bool,Any}
    if bytesavailable(terminal.in_stream) > 0
        c = readkey(terminal.in_stream) |> Int

        c in keys(KEYs) && begin
            key = KEYs[Int(c)]
            retval = key_press(live, key)
            return (live.internals.should_stop, retval)
        end

        # fallback to char key calls
        return key_press(live, Char(c))
    end
    return (false, nothing)
end
