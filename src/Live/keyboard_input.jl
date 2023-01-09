

function keyboard_input(widget::AbstractWidget)
    controls = widget.controls
    if bytesavailable(terminal.in_stream) > 0
        # get input
        c = readkey(terminal.in_stream) 
        c = haskey(KEYs, Int(c)) ? KEYs[Int(c)] : Char(c)

        # see if a control has been defined for this key
        haskey(controls, c) &&  return controls[c](widget, c)

        # see if we can just pass any character
        c isa Char && haskey(controls, Char) &&  return controls[Char](widget, c)
    end
    return []
end



function isactive(widget::AbstractWidget)
    par = AbstractTrees.parent(widget)
    isnothing(par) && return true
    return widget == get_active(par)
end


function keyboard_input(widget::AbstractWidgetContainer)
    if bytesavailable(terminal.in_stream) > 0
        # get input
        c = readkey(terminal.in_stream) 
        c = haskey(KEYs, Int(c)) ? KEYs[Int(c)] : Char(c)

        # execute command on each subwidget
        for wdg in PreOrderDFS(widget)
            controls = wdg.controls

            # only apply to active widget(s)
            isactive(wdg) || continue

            # see if a control has been defined for this key
            haskey(controls, c) && return (controls[c](wdg, c))

            # see if we can just pass any character
            c isa Char && haskey(controls, Char) && return (controls[Char](wdg, c))

            # see if a fallback option is available
            haskey(controls, :setactive) && controls[:setactive](wdg, c)
        end
    end
    return nothing
end

