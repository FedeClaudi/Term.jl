
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
    @assert tabs_width <= console_width()-20 "Not enough space to render tab viewer"
    measure = Measure(
        map(t -> t.measure.h, tabs) |> maximum,
        tabs_width,
    )
    return TabViewer(LiveInternals(), measure, ButtonsMenu(titles; width=10), tabs, :menu)
end

function frame(tb::TabViewer)
    tab = Panel(
        frame(tb.tabs[tb.menu.active]; omit_panel = true);
        width=tb.tabs[tb.menu.active].measure.w,
        padding=(2, 2, 1, 1), 
        style = tb.context == :tab ? "default" : "hidden"

    )
    mn = Panel(frame(tb.menu); 
        width=tb.menu.measure.w+6, height=tab.measure.h,
        padding=(2, 2, 1, 1),
        style = tb.context != :tab ? "default" : "hidden"
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
- {bold white}q{/bold white}: quit program without returning anything

- {bold white}h{/bold white}: toggle help message display

- {bold white}w{/bold white}: toggle help message display for currently active widget
"""
function key_press(tb::TabViewer, c::Char)::Tuple{Bool, Nothing}
    c == 'q' && return (true, nothing)

    tab = tb.tabs[tb.menu.active]

    c == 'h' && begin
        toggle_help(tb)
        return (false, nothing)
    end

    c == 'w' && begin
        toggle_help(tb; help_widget=tab)
        return (false, nothing)
    end

    if tb.context == :tab
        return key_press(tab, c)
    else
        return (false, nothing)
    end
end