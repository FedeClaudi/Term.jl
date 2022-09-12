import ..Layout: vstack
import Term: reshape_text, remove_ansi

# ---------------------------------------------------------------------------- #
#                                     TABS                                     #
# ---------------------------------------------------------------------------- #

abstract type AbstractTab end

function menu_tab(opt::AbstractTab)::Panel
    bg = opt.selected ? "white" : ""
    cl = opt.selected ? "black bold" : "white bold"
    txt = "{$cl on_$bg}$(opt.title){/$cl on_$bg}"
    Panel(
        txt; 
        fit=false,
        style="hidden",
        width=20,
        background=bg,
        justify=:center,
        box=:SQUARE
    )
end

""" capture undefined calls """
key_press(::AbstractTab, ::KeyInput) = nothing
key_press(::AbstractTab, ::KeyInput, ::Any) = nothing



# --------------------------------- text tab --------------------------------- #
mutable struct TextTab <: AbstractTab
    title::String
    content::String
    selected::Bool
    function TextTab(title, content)
        new(title, content, false)
    end
end

display_content(opt::TextTab)::String = opt.content

# --------------------------------- pager tab -------------------------------- #
mutable struct PagerTab <: AbstractTab
    title::String
    content::Vector{String}
    selected::Bool
    tot_lines::Int
    curr_line::Int
    page_lines::Int
    function PagerTab(title, content; page_lines=35)
        content = split(content, "\n")
        new(title, content, false, length(content), 1, page_lines)
    end
end

key_press(p::PagerTab, ::ArrowDown) = p.curr_line = min(p.tot_lines-p.page_lines, p.curr_line+1)
key_press(p::PagerTab, ::ArrowUp)= p.curr_line = max(1, p.curr_line-1)
key_press(p::PagerTab, ::PageDownKey) = p.curr_line = min(p.tot_lines-p.page_lines, p.curr_line+p.page_lines)
key_press(p::PagerTab, ::PageUpKey)= p.curr_line = max(1, p.curr_line-p.page_lines)
key_press(p::PagerTab, ::HomeKey) = p.curr_line = 1
key_press(p::PagerTab, ::EndKey) = p.curr_line = p.tot_lines - p.page_lines
function key_press(p::PagerTab, k::CharKey) 
    if k.char == ']'
        key_press(p, PageDownKey())
    elseif k.char == '['
        key_press(p, PageUpKey())
    end
end

function display_content(tab::PagerTab)::String
    i, Δi = tab.curr_line, tab.page_lines
    page = join(tab.content[max(1, i):min(tab.tot_lines, i+Δi)], "\n")
    return page
end

# ---------------------------------------------------------------------------- #
#                                  TAB VIEWER                                  #
# ---------------------------------------------------------------------------- #

abstract type TVContext end
struct OptionsContext <: TVContext end
struct ContentContext <: TVContext end

mutable struct TabViewer <: AbstractLiveDisplay
    internals::LiveInternals
    options::Vector{AbstractTab}
    selected::Int
    context::TVContext
    needs_update::Bool
    TabViewer(options) = new(LiveInternals(), options, 1, OptionsContext(), true)
end

function shouldupdate(tv::TabViewer) 
    currtime = Dates.value(now())
    isnothing(tv.internals.last_update) && begin
        tv.internals.last_update = currtime
        return true
    end
    
    Δt = currtime - tv.internals.last_update
    if Δt > 250
        tv.internals.last_update = currtime
        return true
    end
    tv.needs_update
end

function toggle_option_select(tv::TabViewer)
    for (i, tab) in enumerate(tv.options)
        tab.selected = i == tv.selected
    end
end

get_active_tab(tv::TabViewer)::AbstractTab = first(filter(o -> o.selected, tv.options))

function frame(tv::TabViewer)::AbstractRenderable
    toggle_option_select(tv)
    options = Panel(
        vstack(menu_tab.(tv.options));
        style=tv.context isa OptionsContext ? "default" : "hidden",
        fit=false,
        width=23,
        height=40,
        padding=(0, 0, 0, 0)
    )

    selected_tab = get_active_tab(tv)
    content_w = console_width() - 23
    tab_content = RenderableText(
        reshape_text((display_content(selected_tab)), content_w-10); 
        width=content_w - 10,
    ) |> string

    content = Panel(
        tab_content,
        style=tv.context isa OptionsContext ? "dim" : "default",
        fit=false,
        title="Tab: " * selected_tab.title,
        width=content_w,
        height=40,
        padding=(4, 4, 1, 1)
    )
    tv.needs_update = false

    return options * content
end




key_press(tv::TabViewer, k) = begin
    tv.needs_update = true
    key_press(tv, (k), tv.context)
end
key_press(tv::TabViewer, ::ArrowLeft) = tv.context = OptionsContext()
key_press(tv::TabViewer, ::ArrowRight) = tv.context = ContentContext()
key_press(tv::TabViewer, ::ArrowDown, ::OptionsContext) = tv.selected = min(length(tv.options), tv.selected+1)
key_press(tv::TabViewer, ::ArrowUp, ::OptionsContext) = tv.selected = max(1, tv.selected-1)

"""
    key_press(tv::TabViewer, k::KeyInput, ::ContentContext)

Let tab type handle key press event
"""
key_press(tv::TabViewer, k::KeyInput, ::ContentContext) = key_press(get_active_tab(tv), k)


""" capture undefined calls """
key_press(tv::TabViewer, ::KeyInput, ::Any) = nothing
