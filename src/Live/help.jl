"""
display/hide help tooltip
"""
function toggle_help(app, args...;)
    internals = app.internals
    width = app.measure.w
    msg =
        if !isnothing(internals.help_message) == true
            parse_md(Markdown.parse(app.internals.help_message); width = width - 6)
        else
            "{dim} no help message shown{/dim}"
        end |> RenderableText

    # get the docstring of the currently active widget
    active_widget = app.widgets[app.active]
    widget_msg =
        something(
            parse_md(getdocs(active_widget); width = max(20, width - 6)),
            "{dim} no help message shown{/dim}",
        ) |> RenderableText

    # get the docstring of each control method
    col = TERM_THEME[].text_accent
    all_controls = [pairs(active_widget.controls)..., pairs(app.controls)...]
    already_added = []
    controls = []

    for (k, c) in all_controls
        (k ∈ already_added || k isa Symbol) && continue

        push!(
            controls,
            RenderableText(
                "{bold $col} - $(k){/bold $col}: " *
                parse_md(getdocs(c); width = max(20, width - 20)),
            ),
        )
        push!(already_added, k)
    end
    # create content
    content = [
        msg,
        "",
        RenderableText(
            md"#### Active widget: $(typeof(active_widget))";
            width = width - 10,
        ),
        "",
        widget_msg,
        "",
        RenderableText(md"#### Controls"; width = width - 10),
        controls...,
    ]

    # create full message
    help_message = Panel(
        content;
        width = width,
        title = "Help",
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
        erase!(app)
        println(stdout, help_message)
        internals.help_shown = true
    end

    internals.prevcontent = nothing
    internals.prevcontentlines = String[]
end
