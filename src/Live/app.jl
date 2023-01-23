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
    parent::Union{Nothing,AbstractWidget}
    compositor::Compositor
    layout::Expr
    width::Int
    height::Int
    expand::Bool
    widgets::AbstractDict
    transition_rules::AbstractDict
    active::Symbol
    on_draw::Union{Nothing,Function}
    on_stop::Union{Nothing,Function}
end

isactive(::App) = true

"""
Execute a transition rule to switch focus to another widget.
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
    :setactive => execute_transition_rule,
)

"""
    App(
        widget::AbstractWidget;
        controls::AbstractDict = app_controls,
        width=1.0,
        height=min(40, console_height()),
        kwargs...
    )

Convenience constructor for an `App` with a single widget.
"""
function App(
    widget::AbstractWidget;
    controls::AbstractDict = app_controls,
    width = 1.0,
    height = min(40, console_height()),
    kwargs...,
)
    layout = :(A($height, $width))
    return App(
        layout;
        widgets = Dict{Symbol,AbstractWidget}(:A => widget),
        controls = controls,
        height = height,
        width = fint(width * console_width()),
        kwargs...,
    )
end

function App(
    layout::Expr;
    widgets::Union{Nothing,AbstractDict} = nothing,
    transition_rules::Union{Nothing,AbstractDict} = nothing,
    width = console_width(),
    height = min(40, console_height()),
    controls::AbstractDict = app_controls,
    on_draw::Union{Nothing,Function} = nothing,
    on_stop::Union{Nothing,Function} = nothing,
    expand::Bool = true,
    help_message::Union{Nothing,String} = nothing,
)

    # parse the layout expression and get the compositor
    compositor = Compositor(
        layout;
        max_w = min(console_width(), width),
        max_h = min(console_height(), height),
    )
    measure = render(compositor).measure

    # if widgets are not provided, create empty widgets placeholders
    widgets = if isnothing(widgets)
        make_placeholders(compositor)
    else
        widgets
    end

    # check that the layout and the widgets match
    layout_keys = compositor.elements |> keys |> collect
    widgets_keys = widgets |> keys |> collect
    @assert issetequal(layout_keys, widgets_keys) "Mismatch between widget names and layout names: $layout_keys vs $widgets_keys"

    on_activated(widgets[first(widgets_keys)])

    # enforce the size of each widget
    widgets = enforce_app_size(compositor, widgets)

    transition_rules =
        isnothing(transition_rules) ? infer_transition_rules(layout) : transition_rules

    msg_style = TERM_THEME[].emphasis
    app = App(
        AppInternals(; help_message = help_message),
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
    infer_transition_rules(layout::Expr)::Dict

If no transition rules are passed, infer them from the layout's
spatial relationships.
"""
function infer_transition_rules(layout::Expr)::Dict
    """ recursively get widgets in a  layout elements """
    function get_elements(elem::Expr)
        out = []
        for node in PreOrderDFS(elem)
            node isa Expr || continue
            node.args[1] ∉ (:*, :/) && push!(out, node.args[1])
        end
        return out
    end
    get_elements(x) = nothing

    transition_rules = Dict(
        ArrowRight() => Dict(),
        ArrowLeft() => Dict(),
        ArrowDown() => Dict(),
        ArrowUp() => Dict(),
    )

    for node in PreOrderDFS(layout)
        if node isa Expr
            op = node.args[1]
            op ∈ (:*, :/) || continue
            source = get_elements(node.args[2])
            dest = get_elements(node.args[3])

            # store commands to and from widgets
            first_key, second_key =
                op == :* ? (ArrowRight(), ArrowLeft()) : (ArrowDown(), ArrowUp())
            for w in source
                transition_rules[first_key][w] = dest[1]
            end
            for w in dest
                transition_rules[second_key][w] = source[1]
            end
        end
    end

    return transition_rules
end

"""
If no widget was passed, create placeholder widgets.
"""
function make_placeholders(compositor)
    elements = compositor.elements
    colors = if length(elements) > 1
        getfield.(Palette(blue, pink; N = length(elements)).colors, :string)
    else
        [pink]
    end

    ws = Dict()
    for (i, (name, elem)) in enumerate(pairs(elements))
        ws[name] = PlaceHolderWidget(elem.h, elem.w, string(name), colors[i])
    end
    return ws
end

"""
    enforce_app_size(compositor::Compositor, widgets::AbstractDict)

Called when an App is first created to set the size of all widgets.
"""
function enforce_app_size(compositor::Compositor, widgets::AbstractDict)
    _keys = widgets |> keys |> collect

    for k in _keys
        elem, wdg = compositor.elements[k], widgets[k]
        wdg.internals.measure = Measure(elem.h, elem.w)
        on_layout_change(wdg, wdg.internals.measure)
    end
    return widgets
end

"""
    enforce_app_size(app::App, measure::Measure)

Called when a console is resized to adjust the apps layout. 
"""
function enforce_app_size(app::App, measure::Measure)
    compositor = Compositor(app.layout; max_w = measure.w, max_h = measure.h)
    _keys = app.widgets |> keys |> collect

    for k in _keys
        elem, wdg = compositor.elements[k], app.widgets[k]
        wdg.internals.measure = Measure(elem.h, elem.w)
        on_layout_change(wdg, wdg.internals.measure)
    end

    app.compositor = compositor
end

# ----------------------------------- frame ---------------------------------- #

"""
    on_layout_change(app::App)

Called when the console is resized to adjust the apps layout.
"""
function on_layout_change(app::App)
    new_width = app.expand ? console_width() : min(app.width, console_width())
    new_width == app.measure.w && return

    erase!(app)
    clear(stdout)

    # the console is too small, re-design
    app.measure = Measure(app.measure.h, new_width)
    enforce_app_size(app, app.measure)
end

"""
    frame(app::App)

Render the app and its content.
"""
function frame(app::App; kwargs...)
    isnothing(app.on_draw) || app.on_draw(app)

    # adjust size to changes in console
    on_layout_change(app)

    for (name, widget) in pairs(app.widgets)
        # toggle active
        if length(app.widgets) > 1
            app.active == name ? widget.internals.on_activated(widget) :
            widget.internals.on_deactivated(widget)
        end

        content = frame(widget)

        update!(app.compositor, name, content)
    end

    # reset the activation state of each widget
    for widget in values(app.widgets)
        # wasactive, willbeactive = widget.internals.active, isactive(widget)
        # !wasactive && willbeactive && widget.internals.on_activated(widget)

        widget.internals.active = isactive(widget)
    end

    return render(app.compositor)
end

"""
    add_debugging_info!(content::AbstractRenderable, app::App)::AbstractRenderable

Add debugging information to the top of the app.
"""
function add_debugging_info!(content::AbstractRenderable, app::App)::AbstractRenderable
    # print the app's layout as a TREE
    tree = sprint(print, app)

    debug_info = Panel(tree; width = content.measure.w)
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
