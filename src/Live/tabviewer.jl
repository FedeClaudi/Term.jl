
"""
`TabViewer` displays multiple live widgets using a menu
to let the user chose which widget to view at a given time.
"""
mutable struct TabViewer <: AbstractWidget
    internals::LiveInternals
    measure::Measure
    menu::ButtonsMenu
    tabs::Vector{AbstractWidget}
    context::Symbol
end


function TabViewer(titles::Vector, tabs::Vector)
    @assert length(titles) == length(tabs)

    tabs_width = map(t -> t.measure.w, tabs) |> maximum
    tabs_height = map(t -> t.measure.h, tabs) |> maximum
    @assert tabs_width <= console_width()-26 "Not enough space to render tab viewer"
    measure = Measure(
        tabs_height + 4,
        tabs_width,
    )
    return TabViewer(LiveInternals(), measure, ButtonsMenu(titles; width=15), tabs, :menu)
end

function frame(tb::TabViewer; kwargs...)
    tab = Panel(
        frame(tb.tabs[tb.menu.active]; omit_panel = false);
        width=tb.tabs[tb.menu.active].measure.w+4,
        height=tb.measure.h,
        padding=(1, 1, 0, 0), 
        style = tb.context == :tab ? "dim" : "hidden"

    )
    mn = Panel(frame(tb.menu); 
        width=tb.menu.measure.w+2, height=tb.measure.h,
        padding=(0, 0, 1, 1),
        style = tb.context != :tab ? "dim" : "hidden",
        justify=:center,
        )
    
    return mn * "   " *  tab
end

"""
- {bold white}arrow right{/bold white}: switch focus to currently active widget
"""
function key_press(tb::TabViewer, ::ArrowRight)
    tb.context=:tab
end

"""
- {bold white}arrow left{/bold white}: switch focus to widget selection menu
"""
function key_press(tb::TabViewer, ::ArrowLeft)
    tb.context=:menu
end

function key_press(tb::TabViewer, ::Enter) 
    if tb.context == :menu
        tb.internals.should_stop = true
        return nothing
    else
        tab = tb.tabs[tb.menu.active]
        return key_press(tab, Enter())
    end
end

function key_press(tb::TabViewer, ::Esc) 
    tb.internals.should_stop = true
    return nothing
end

"""
- all other keys presses are passed to the currently active widget.
"""
function key_press(tb::TabViewer, k::KeyInput)
    if tb.context == :menu
        key_press(tb.menu, k)
    else
        tab = tb.tabs[tb.menu.active]
        key_press(tab, k)
    end
end


"""
- [on menu focus] {bold white}q{/bold white}: quit program without returning anything

- [on menu focus] {bold white}h{/bold white}: toggle help message display

- [on menu focus] {bold white}w{/bold white}: toggle help message display for currently active widget
"""
function key_press(tb::TabViewer, c::Char)::Tuple{Bool, Nothing}
    tab = tb.tabs[tb.menu.active]

    if tb.context == :tab
        return key_press(tab, c)
    else
        c == 'q' && return (true, nothing)    
        c == 'h' && begin
            toggle_help(tb)
            return (false, nothing)
        end
    
        c == 'w' && begin
            toggle_help(tb; help_widget=tab)
            return (false, nothing)
        end
        return (false, nothing)
    end
end