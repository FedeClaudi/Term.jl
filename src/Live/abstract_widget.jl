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

# ----------------------------- widget functions ----------------------------- #

get_active(::AbstractWidget) = nothing

function isactive(widget::AbstractWidget)
    par = AbstractTrees.parent(widget)
    isnothing(par) && return true
    return widget == get_active(par) && isactive(par)
end


quit(::Nothing) = return
quit(widget::AbstractWidget, ::Any) = quit(AbstractTrees.parent(widget))
quit(widget::AbstractWidget) = quit(AbstractTrees.parent(widget))


"""
Get the current conttent of a widget
"""
frame(::AbstractWidget) = error("Not implemented")


# ------------------------------ tree structure ------------------------------ #
function AbstractTrees.children(widget::AbstractWidget) 
    hasfield(typeof(widget), :widgets) || return []
    widget.widgets isa AbstractDict && return collect(values(widget.widgets))
    return widget.widgets
end

function AbstractTrees.parent(widget::AbstractWidget)
    return widget.parent
end

function print_node(io, x) 
    color = isactive(x) ? "green" : "dim red"
    h, w = x.measure.h, x.measure.w

    msg = "{$color}$(typeof(x)){/$color} {white dim}($h, $w){/white dim}"
    tprint(io, msg)
end


Base.print(io::IO, widget::AbstractWidget) = print_tree(print_node, io, widget)

