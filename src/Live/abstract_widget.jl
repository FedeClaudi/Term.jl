# ---------------------------------------------------------------------------- #
#                                ABSTRACT WIDGET                               #
# ---------------------------------------------------------------------------- #

"""
    AbstractWidget

Abstract widgets must have three obligatory fields:
    measure::Measure
    controls:: Dict{Union{KeyInput, Char}, Function}
    parent::Union{Nothing, AbstractWidget}

and one optional one
    on_draw::Union{Nothing, Function} = nothing
"""
abstract type AbstractWidget end

"""
    WidgetInternals

This struct is used to store the internal state of a widget as well as
callbacks assigned to it.
"""
mutable struct WidgetInternals
    measure::Measure
    parent::Union{Nothing,AbstractWidget}
    on_draw::Union{Nothing,Function}
    on_activated::Function
    on_deactivated::Function
    active::Bool
end

# ----------------------------- widget functions ----------------------------- #
"""
    get_active(w::AbstractWidget)

Nothing: no children.
"""
get_active(::AbstractWidget) = nothing

"""
    isactive(w::AbstractWidget)

Returns true if the widget is active, i.e. if it is the active widget
"""
function isactive(widget::AbstractWidget)
    par = AbstractTrees.parent(widget)
    isnothing(par) && return true
    return widget == get_active(par) && isactive(par)
end

"""
Default callback for a widget being activated
"""
on_activated(wdg::AbstractWidget) = wdg.internals.active = true

"""
Default callback for a widget being deactivated
"""
on_deactivated(wdg::AbstractWidget) = wdg.internals.active = false

"""
Quit the current app, potentially returning some value.
"""
function quit end
quit(::Nothing) = return
quit(widget::AbstractWidget, ::Any) = quit(AbstractTrees.parent(widget))
quit(widget::AbstractWidget) = quit(AbstractTrees.parent(widget))

"""
Get the current content of a widget
"""
frame(::AbstractWidget) = error("Not implemented")

# ------------------------------ tree structure ------------------------------ #

"""
Methods to let the AbstractTrees API handle applications as tree
structures based on the nesting of widgets.
"""

function AbstractTrees.children(widget::AbstractWidget)
    hasfield(typeof(widget), :widgets) || return []
    widget.widgets isa AbstractDict && return collect(values(widget.widgets))
    return widget.widgets
end

function AbstractTrees.parent(widget::AbstractWidget)
    hasfield(typeof(widget), :parent) && return widget.parent
    return widget.internals.parent
end

"""
    print_node(io, x) 

Print function to print a node (widget) in an application's hierarchy tree. 
It prints the node's stated dimensions vs its content's (calling `frame`).
Used for debugging
"""
function print_node(io, x)
    color = isactive(x) ? "bright_blue" : "dim blue"
    style = isactive(x) ? "default" : "dim"
    content = frame(x)

    measure = hasfield(typeof(x), :measure) ? x.measure : x.internals.measure
    hx, wx = measure.h, measure.w
    hc, wc = content.measure.h, content.measure.w

    h_color = hx >= hc ? style : "red"
    w_color = wx >= wc ? style : "red"

    msg = """{$color}$(typeof(x)){/$color} {dim} ($hx, $wx){/dim}
           {$style}content: ({$h_color}$hc{/$h_color}, {$w_color}$wc{/$w_color}){/$style}"""
    print(io, apply_style(msg))
end

Base.print(io::IO, widget::AbstractWidget) = print_tree(print_node, print, io, widget)
