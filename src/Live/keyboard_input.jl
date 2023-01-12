

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



function keyboard_input(widget::AbstractWidgetContainer)
    retvals = []
    if bytesavailable(terminal.in_stream) > 0
        # get input
        c = readkey(terminal.in_stream) 
        c = haskey(KEYs, Int(c)) ? KEYs[Int(c)] : Char(c) # ::Union{Char, KeyInput}

        # execute command on each subwidget
        for wdg in PreOrderDFS(widget)
            retval = nothing
            controls = wdg.controls

            # only apply to active widget(s)
            isactive(wdg) || continue

            # see if a control has been defined for this key
            haskey(controls, c) && (retval = controls[c](wdg, c))

            # see if we can just pass any character
            c isa Char && haskey(controls, Char) && (retval = controls[Char](wdg, c))

            # see if a fallback option is available
            haskey(controls, :setactive) && controls[:setactive](wdg, c)

            # if retval says so, stop looking at other widgets here
            retval == :stop && break
            isnothing(retval) || push!(retvals, retval)
        end
    end
    return retvals
end

