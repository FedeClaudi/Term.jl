
"""
    keyboard_input(widget::AbstractWidget)

Get keyboard input from the terminal and execute the corresponding control function
if it exists. Returns a list of return values from the control functions.
"""
function keyboard_input(widget::AbstractWidget)
    controls = widget.controls
    if bytesavailable(terminal.in_stream) > 0
        # get input
        c = readkey(terminal.in_stream)
        c = haskey(KEYs, Int(c)) ? KEYs[Int(c)] : Char(c)

        # see if a control has been defined for this key
        haskey(controls, c) && return controls[c](widget, c)

        # see if we can just pass any character
        c isa Char && haskey(controls, Char) && return controls[Char](widget, c)
    end
    return []
end

"""
    keyboard_input(widget::AbstractWidgetContainer) 

Get keyboard input from the terminal and execute the corresponding control function for active widgets.
"""
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

            # see if key is an app control key
            haskey(controls, :setactive) && begin
                control_exectued = controls[:setactive](wdg, c)
                control_exectued && return retval
            end

            # only apply to active widget(s)
            isactive(wdg) || continue

            # see if a control has been defined for this key
            haskey(controls, c) && (retval = controls[c](wdg, c))

            # see if we can just pass any character
            c isa Char && haskey(controls, Char) && (retval = controls[Char](wdg, c))

            # if retval says so, stop looking at other widgets here
            retval == :stop && break
            isnothing(retval) || push!(retvals, retval)
        end
    end
    return retvals
end
