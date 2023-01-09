"""
toggle_help(live::AbstractWidget; help_widget::Union{Nothing, AbstractWidget}=nothing)

Toggle help tooltip display for a widget widget.

By default the help message of `live` is shown, but for "nested" widgets one can 
directly specify for which widget to look up the help message for with `help_widget`.

The help message itself is made up of the docstring for the `live` struct and the docstrings
of all methods for `key_press(typeof(live), ::Any)`.
"""
function toggle_help(live, args...; help_widget = nothing)
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


function active_widget_help(widget, args...)
    widget.internals.help_shown && toggle_help(widget)
    active = widget.widgets[widget.active]
    toggle_help(widget, args...;  help_widget=active)
end