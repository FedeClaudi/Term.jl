mutable struct TabViewer <: AbstractLiveDisplay
    internals::LiveInternals
    measure::Measure
    menu::ButtonsMenu
    tabs::Vector{AbstractLiveDisplay}
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


function key_press(tb::TabViewer, ::ArrowRight)
    tb.context=:tab
end

function key_press(tb::TabViewer, ::ArrowLeft)
    tb.context=:menu
end

function key_press(tb::TabViewer, k::Union{CharKey, KeyInput})
    if tb.context == :menu
        key_press(tb.menu, k)
    else
        tab = tb.tabs[tb.menu.active]
        key_press(tab, k)
    end
end

# function key_press(live::TabViewer, k::CharKey)
#     k.char == 'q' && return (true, nothing)
#     k.char == 'h' && begin
#         help(live)
#         return (false, nothing)
#     end
#     return (false, nothing)
# end