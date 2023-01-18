# ---------------------------------------------------------------------------- #
#                                APP  INTERNALS                                #
# ---------------------------------------------------------------------------- #
"""
struct AppInternals
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

`AppInternals` handles "under the hood" work for live widgets. 
It takes care of keeping track of information such as the content
displayed at the last refresh of the widget to inform the printing
of the widget's content at the next refresh.

AppInternals also holds linked_widgets which can be used to link to 
other widgets to access their internal variables.
"""
@with_repr mutable struct AppInternals
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

    function AppInternals(; refresh_rate::Int = 60, help_message = nothing)
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
#                                      APP                                     #
# ---------------------------------------------------------------------------- #

# ------------------------------- CONSTRUCTORS ------------------------------- #
"""
An `App` is a collection of widgets.

!!! tip
    Transition rules bind keys to "movement" in the app to change
    focus to a different widget
"""
@with_repr mutable struct App <: AbstractWidgetContainer
    internals::AppInternals
    measure::Measure
    controls::AbstractDict
    parent::Union{Nothing, AbstractWidget}
    compositor::Compositor
    layout::Expr
    width::Int
    height::Int
    expand::Bool
    widgets::AbstractDict
    transition_rules::AbstractDict
    active::Symbol
    on_draw::Union{Nothing,Function}
    on_stop::Union{Nothing, Function}
end

"""
    execute_transition_rule(app::App, key)

Looks up a `transition_rules` entry matching the current situation. 
There has to be a ruleset for the key the user pressed and within
the ruleset there must be an entry matching the currently active 
widget, otherwise no effect. 
"""
function execute_transition_rule(app::App, key)::Bool
    haskey(app.transition_rules, key) || return false
    rulesset = app.transition_rules[key]
    haskey(rulesset, app.active) || return false
    app.active = rulesset[app.active]
    return true
end


function quit(app::App)
    app.internals.should_stop = true
    return nothing
end


app_controls = Dict(
    'q' => quit,
    Esc() => quit,
    'h' => toggle_help,
    'w' => active_widget_help,
    :setactive => execute_transition_rule
)


function App(
    widget::AbstractWidget;
    controls::AbstractDict = app_controls,
    width=1.0,
    height=min(40, console_height()),
    kwargs...
)
    layout = :(A($height, $width))
    return App(
        layout, Dict{Symbol,AbstractWidget}(:A => widget); controls=controls, 
        height=height, width=fint(width * console_width()), 
        kwargs...
    )
end


function App(
    layout::Expr,
    widgets::AbstractDict,
    transition_rules::Union{Nothing,AbstractDict} = nothing;
    width=console_width(),
    height=min(40, console_height()),
    controls::AbstractDict = app_controls, 
    on_draw::Union{Nothing,Function} = nothing,
    on_stop::Union{Nothing,Function} = nothing,
    expand::Bool = true,
)

    # parse the layout expression and get the compositor
    compositor = Compositor(layout; max_w = min(console_width(), width), max_h = min(console_height(), height))
    measure = render(compositor).measure

    # check that the layout and the widgets match
    layout_keys = compositor.elements |> keys |> collect
    widgets_keys = widgets |> keys |> collect
    @assert issetequal(layout_keys, widgets_keys) "Mismatch between widget names and layout names"

    # enforce the size of each widget
    widgets = enforce_app_size(compositor, widgets)

    transition_rules =
        isnothing(transition_rules) ? Dict() :
        transition_rules

    # make a help message to show transition rules
    color = TERM_THEME[].emphasis_light
    transition_rules_message = []
    for (key, cmds) in pairs(transition_rules)
        for (a, b) in pairs(cmds)
            push!(
                transition_rules_message,
                "{$color}$key {/$color} moves from {$(color)}$a {/$color} to {$color}$b {/$color}",
            )
        end
    end

    msg_style = TERM_THEME[].emphasis
    app = App(
        AppInternals(;
            help_message = "\n{$msg_style}Transition rules{/$msg_style}" /
                           join(transition_rules_message, "\n"),
        ),
        measure,
        controls,
        nothing,
        compositor,
        layout,
        width, 
        height,
        expand,
        widgets,
        transition_rules,
        widgets_keys[1],
        on_draw,
        on_stop,
    )

    set_as_parent(app)
    return app
end

"""
    enforce_app_size(compositor::Compositor, widgets::AbstractDict)

Called when an App is first created to set the size of all widgets.
"""
function enforce_app_size(compositor::Compositor, widgets::AbstractDict)
    _keys = widgets |> keys |> collect

    for k in _keys
        elem, wdg = compositor.elements[k], widgets[k]
        wdg.measure = Measure(elem.h-1, elem.w)
        on_layout_change(wdg, wdg.measure)
    end
    return widgets
end

"""
    enforce_app_size(app::App, measure::Measure)

Called when a console is resized to adjust the apps layout. 
"""
function enforce_app_size(app::App, measure::Measure)
    compositor = Compositor(app.layout; max_w=measure.w, max_h = measure.h)
    _keys = app.widgets |> keys |> collect

    for k in _keys
        elem, wdg = compositor.elements[k], app.widgets[k]
        wdg.measure = Measure(elem.h-1, elem.w)
        on_layout_change(wdg, wdg.measure)
    end

    app.compositor = compositor
end

# ----------------------------------- frame ---------------------------------- #
function on_layout_change(app::App)
    console_h = min(app.height, console_height())
    console_w = app.expand ? console_width() :  min(app.width, console_width())
    (console_h >= app.measure.h && console_w == app.measure.w) && return

    erase!(app)
    clear(stdout)

    # the console is too small, re-design
    app.measure = Measure(console_h, console_w)
    enforce_app_size(app, app.measure)
end


function frame(app::App; kwargs...)
    isnothing(app.on_draw) || app.on_draw(app)

    # adjust size to changes in console
    on_layout_change(app)

    for (name, widget) in pairs(app.widgets)
        content = frame(widget)
        if length(app.widgets) > 1
            content = app.active == name ? widget.on_highlighted(content) : widget.on_not_highlighted(content)
        end
        update!(app.compositor, name, content)
    end
    return render(app.compositor)
end


function add_debugging_info!(content::AbstractRenderable, app::App)::AbstractRenderable
    # print the app's layout as a TREE
    tree = sprint(print, app)

    debug_info = Panel(
        tree;
        width = content.measure.w,
    )
    return debug_info / content
end



# ---------------------------------------------------------------------------- #
#                                   RENDERING                                  #
# ---------------------------------------------------------------------------- #

"""
    shouldupdate(app::App)::Bool

Check if a widget's display should be updated based on:
    1. enough time elapsed since last update
    2. the widget has not beed displayed het
"""
function shouldupdate(app::App)::Bool
    currtime = Dates.value(now())
    isnothing(app.internals.last_update) && begin
        app.internals.last_update = currtime
        return true
    end

    Δt = currtime - app.internals.last_update
    if Δt > app.internals.refresh_Δt
        app.internals.last_update = currtime
        return true
    end
    return false
end

"""
    replace_line(internals::AppInternals)

Erase a line and move cursor
"""
function replace_line(internals::AppInternals)
    erase_line(internals.ioc)
    down(internals.ioc)
end

"""
    replace_line(internals::AppInternals, newline)

Erase a line, write new content and move cursor. 
"""
function replace_line(internals::AppInternals, newline)
    erase_line(internals.ioc)
    println(internals.ioc, newline)
end


"""
    refresh!(live::AbstractWidget)::Tuple{Bool, Any}

Update the terminal display of a app.

this is done by calling `frame` on the app to get the new content.
Then, line by line, the new content is compared to the previous one and when
a discrepancy occurs the lines gets re-written. 
This is all done printing to a buffer first and then to `stdout` to avoid
jitter.
"""
function refresh!(app::App)
    # check for keyboard inputs
    retval = keyboard_input(app)
    app.internals.should_stop && return something(retval, [])

    # check if its time to update
    shouldupdate(app) || return nothing

    # get new content
    internals = app.internals
    content::AbstractRenderable = frame(app)

    LIVE_DEBUG[] == true && begin
        content = add_debugging_info!(content, app)
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
    erase!(app::App)

Erase a app from the terminal.
"""
function erase!(app::App)
    isnothing(app.internals.prevcontent) && return

    nlines = app.internals.prevcontent.measure.h
    up(app.internals.ioc, nlines)
    cleartoend(app.internals.ioc)
    write(stdout, take!(app.internals.iob))
    nothing
end

"""
    stop!(app::App)

Restore normal terminal behavior.
"""
function stop!(app::App)
    Base.stop_reading(stdin)

    internals = app.internals
    print(internals.term.out_stream, "\x1b[?25h") # unhide cursor
    print(stdout, "\x1b[?25h")
    raw!(internals.term, false)
    nothing
end

"""
    play(app::App; transient::Bool=true)

Keep refreshing a renderable, until the user interrupts it. 
"""
function play(app::App; transient::Bool = true)
    Base.start_reading(stdin)

    retval = nothing
    while isnothing(retval)
        retval = refresh!(app)
    end
    stop!(app)
    transient && erase!(app)

    retval = length(retval) > 0 ? retval[1] : retval
    return retval
end






