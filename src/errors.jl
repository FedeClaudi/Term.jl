module errors
    import Base: InterpreterIP, show_method_candidates, ExceptionStack

    import Term: theme, highlight, reshape_text, read_file_lines, load_code_and_highlight, split_lines
    import Term.style: apply_style
    import ..panel: Panel, TextBox
    import ..renderables: RenderableText
    import ..layout: hLine
    import ..consoles: Console

    export install_stacktrace

    const ErrorsExplanations = Dict(
        ArgumentError   => "The parameters to a function call do not match a valid signature.",
        AssertionError  => "comes up when an assertion's check fails. For example `@assert 1==2` will throw an AssertionError",
        BoundsError     => "comes up when trying to acces a container at invalid position (e.g. a string a='abcd' with 4 characters cannot be accessed as a[5]).",
        ErrorException  => "is a generic error type",
        LoadError       => "occurs while using 'include', 'require' or 'using'",
        MethodError     => "comes up when to method can be found with a given name and for a given set of argument types.",
        UndefVarError   => "comes up when a variable is used which is either not defined, or, which is not visible in the current variables scope (e.g.: variable defined in function A and used in function B)",
    )
    
    _width() = min(Console(stderr).width, 120)

    _highlight(x::Union{Symbol, AbstractString}) = "[$(theme.symbol)]$x[/$(theme.symbol)]"
    _highlight(x::Number) = "[$(theme.number)]$x[/$(theme.number)]"
    _highlight(x::DataType) = "[$(theme.type) dim]::$(x)[/$(theme.type) dim]"
    _highlight(x::UnitRange) = _highlight(string(x))
    _highlight(x::Union{AbstractArray, AbstractVector, AbstractMatrix}) =  "[$(theme.number)]$x[/$(theme.number)]"

    function _highlight(x)
        # @info "highlighting misterious object" x typeof(x)
        return _highlight(string(x))
    end


    # --------------------------------- messages --------------------------------- #

    # ! ARGUMENT ERROR
    function error_message(io::IO, er::ArgumentError)
        return er.msg, ""
    end

    # ! ASSERTION ERROR
    function error_message(io::IO, er::AssertionError)
        return er.msg, ""
    end

    # ! BOUNDS ERROR
    function error_message(io::IO, er::BoundsError)
        # @info "bounds error" er fieldnames(typeof(er))
        main_msg = "Attempted to access $(_highlight(er.a))$(_highlight(typeof(er.a))) at index $(_highlight(er.i))$(_highlight(typeof(er.i)))\n\n"

        additional_msg = "[dim]no additional message found[/dim]"

        if isdefined(er, :a)
            if er.a isa AbstractString
                nunits = ncodeunits(er.a)
                additional_msg = "String has $nunits codeunits, $(length(er.a)) characters."
            end
        else
            additional_msg ="[red]Variable is not defined!.[/red]" 
        end
        return main_msg, additional_msg
    end

    # ! EXCEPTION ERROR
    function error_message(io::IO, er::ErrorException)
        # @info "err exceprion" er fieldnames(ErrorException) er.msg
        msg = split(er.msg, " around ")[1]
        return msg, ""
    end

    # ! LoadError
    function error_message(io::IO, er::LoadError)
        # @warn "load err" er fieldnames(ErrorException)
        # msg =  hasfield(typeof(er), :msg) ? er.msg : string(er)
        msg = "at [dim]$(er.file) line $(er.line)[/dim]"
        subm = "Original error: [red]$(er.error)[/red]"
        return msg, subm
    end

    # ! METHOD ERROR
    _method_regexes = [
        r"!Matched+[:a-zA-Z]*\{+[a-zA-Z\s \,]*\}",    
        r"!Matched+[:a-zA-Z]*",
    ]
    function error_message(io::IO, er::MethodError; kwargs...)
        # @info "er" er.f er.args er.world er.args[1] typeof(er.args[1])

        # get main error message
        _args = join([string(ar)*_highlight(typeof(ar)) for ar in er.args], ", ")
        fn_name = "$(_highlight(string(er.f)))"
        main_line = "No method matching $fn_name(" * _args * ")"

        # get recomended candidates
        _candidates = split(sprint(show_method_candidates, er; context=io), "\n")
        candidates::Vector{String} = []

        for can in _candidates[3:end-1]
            fun, file = split(can, " at ")
            name, args = split(fun, "(", limit=2)
            # name = "[red]$name[/red]"

            for regex in _method_regexes
                for match in collect(eachmatch(regex, args))
                    args = replace(args, match.match=>"[dim red]$(match.match[9:end])[/dim red]")
                end
            end

            file, lineno = split(file, ":")

            # println(RenderableText(name, "red"))
            push!(candidates, "   " * fn_name * "("*args)
            push!(candidates, "[dim]$file [bold dim](line: $lineno)[/bold dim][/dim]\n")

        end
        candidates = length(candidates) == 0 ?  ["[dim]no candidate method found[/dim]"] : candidates

        return main_line * "\n",  Panel(
            "\n" * join(candidates, "\n"),
            width=_width() - 10,
            title="closest candidates",
            title_style="yellow",
            style="blue dim",
            )
    end

    # ! UNDEFVAR ERROR
    function error_message(io::IO, er::UndefVarError) 
        # @info "undef var error" er er.var typeof(er.var)
        var = string(er.var)
        "Undefined variable '$(_highlight(er.var))'.", ""
    end


    # ! STRING INDEX ERROR
    function error_message(io::IO, er::StringIndexError)
        # @info er typeof(er) fieldnames(typeof(er)) 
        m1 = "attempted to access a String at index $(er.index)\n"
        return m1, ""
    end



    # ! catch all other errors
    function error_message(io::IO, er) 
        @info er typeof(er) fieldnames(typeof(er)) 
        if hasfield(typeof(er), :error)
            # @info "nested error" typeof(er.error)
            m1, m2 = error_message(io, er.error)
            msg = "[bold red]LoadError:[/bold red]\n" * m1
        else
            msg = hasfield(typeof(er), :msg) ? er.msg : "no message for error of type $(typeof(er)), sorry."
            m2 = ""
        end
        return msg, m2
    end


    # ----------------------------- styling functions ---------------------------- #
    function style_error(io::IO, er)
        if haskey(ErrorsExplanations, typeof(er))
            info_msg = ErrorsExplanations[typeof(er)]
        else
            info_msg = "no additional info available."
        end
        
        WIDTH = _width()
        main_message, message = error_message(io, er)
        # @info "Got styled error" er main_message info_msg


        # create panel and text
        panel = Panel(
            # main_message,
            message,
            hLine(WIDTH-4; style="red dim"),
            RenderableText("[grey89 dim][bold red dim]$(typeof(er)):[/bold red dim] " * info_msg * "[/grey89 dim]"; width=WIDTH-4),
            title="ERROR: [bold indian_red]$(typeof(er))[/bold indian_red]",
            title_style="red",
            style = "dim red",
            width=WIDTH,
            title_justify=:center,
        )
        text = RenderableText("\n[bold indian_red]$(typeof(er)):[/bold indian_red] $main_message")

        return panel,  text
    end


    """
    creates a sub-panel within a backtrace panel showing code where the error happened
    """
    function backtrace_subpanel(line::String, WIDTH::Int, title::String)
        # @info "getting subpanel"
        # get path to file and line number
        file = split(split_lines(line)[2], " [bold dim]")[1][13:end]
        file, lineno = split(file, ":")
        lineno = parse(Int, lineno)
        # @info "got file and lines" file lineno
        
        # read and highlight text
        code = ""
        try
            code = load_code_and_highlight(file, lineno; δ=3)
            code = length(code) > 0 ? TextBox(code, width=WIDTH-6) : ""
        catch SystemError  # file not found
            # @warn "Failed to get code"
            code = ""
        end

        return Panel(
            "\n",
            line,
            code,
            title=title,
            width=WIDTH-4,
            style="dim blue",
            title_style="bold bright_yellow",
        )
    end

    function style_backtrace(io::IO, t::Vector)
        # @info "styling backtrace"
        WIDTH = _width()
        
        # create text
        stack_lines::Vector{String} = []
        for (n, frame) in enumerate(t)
            if typeof(frame) ∉ (Ptr, InterpreterIP)
                func_line = "[light_yellow3]($n)[/light_yellow3] [sky_blue3]$(frame.func)[/sky_blue3]"
                file_line = "       [dim]$(frame.file):$(frame.line) [bold dim](line: $(frame.line))[/bold dim][/dim]"
                push!(stack_lines, func_line * "\n" * file_line * "\n" )

            end
        end

        # create layout
        # @info "creating stack panels" length(stack_lines)
        if length(stack_lines) > 0
            if length(stack_lines) > 1
                error_line = backtrace_subpanel(stack_lines[1], WIDTH, "error in")
            else
                error_line = ""
            end

            # @info "error line ready" error_line length(stack_lines)
            if length(stack_lines) > 3
                above = TextBox(
                    join(stack_lines[2:end-1], "\n"),
                    width=WIDTH-8
                )
            elseif length(stack_lines) > 2
                above = TextBox(
                    stack_lines[2],
                    width=WIDTH-8
                )
            else
                above = ""
            end
            # @info "above ready"

            offending = backtrace_subpanel(stack_lines[end], WIDTH, "caused by")
            stack = error_line / above / offending
            # @info "stacked"
        else
            stack = "[dim]No stack trace[/dim]"
        end

        # create output
        # @info "creating panel"
        try
            panel = Panel(
                    stack,
                    title="StackTrace",
                    style="yellow dim",
                    title_style="yellow",
                    title_justify=:left,
                    width=WIDTH
                )
            # @info "panel ready"
            return panel
        catch err
            @warn "failed to crate panel" err
            println(stack)
            return stack
        end

    end

    """
    Styles a symple `stcktrace()`
    """
    function style_stacktrace(stack::Vector)
        lines::Vector{String} = []
        for (n, frame) in enumerate(stack)
            if typeof(frame) ∉ (Ptr. Ptr{Nothing}, InterpreterIP)
                push!(lines, apply_style("[bright_blue dim]($n)[/bright_blue dim] [yellow]$(frame.func)[/yellow] - [dim]$(line.file):$(line.line)[/dim]"))
            end
        end

        return join(lines, "\n")
    end

    # ---------------------------------------------------------------------------- #
    #                              INSTALL TRACESTACK                              #
    # ---------------------------------------------------------------------------- #
    function install_stacktrace()
        @eval begin

            # ---------------------------- handle load errors ---------------------------- #
            function Base.showerror(io::IO, ex::LoadError, bt; backtrace=true)
                Base.showerror(io, ex.error, bt; backtrace=true)
            end


            function Base.showerror(io::IO, ex, bt; backtrace=true)
                try
                    println("\n")
                    # @info "loaderror"

                    stack = style_backtrace(io, bt)
                    # @info "error stack ready"

                    err, err_msg = style_error(io, ex)
                    # @info "error message ready" stack err err_msg
                
                    println(stack / err / err_msg)
                    # @info "error message printed" 
                catch err
                    @error "Error in error rendering!!" err typeof(err) ex
                    println(apply_style("[bold red]Error[/bold red][red bold dim] (during error message geneneration):[/red bold dim]"))

                    
                    # attemp to render individual parts
                    try
                        println(style_backtrace(io, stacktrace()))
                    catch newerr
                        @warn "failed to produce error stack" newerr
                        println(apply_style("[bold yellow]Error stack trace:"))
                        
                        println(style_stacktrace(stacktrace()))

                        println(apply_style("\n\n[bold yellow]Error back trace[bold yellow]"))
                        println(style_stacktrace(bt))
                        print("\n")
                    end

                    try
                        fmterr, err_msg = style_error(io, err)
                        println(fmterr / err_msg)
                    catch newerr
                        @warn "failed to produce error message" newerr
                        println("\e[31m" * err * "\e[0m")
                    end

                    println(apply_style("[red bold dim]End of error during error message generation[/red bold dim]\n\n"))
                    println(apply_style("[orange1]Original error:[/orange1][indian_red] $ex [/indian_red]\n[orange1]Backtrace:[/orange1]"))
                    println.(style_stacktrace(bt))

                end
            end

            # ------------------ handle all other errors (no backtrace) ------------------ #
            """
            Re-define Base module function. Prints a nicely formatted error message, but only
            if the error wasn't nested in a LoadError. In that case `Base.showerror(io::IO, ex::LoadError, bt; backtrace=true)`
            handles all the printing and printing the message here would cause a duplicate.
            """

            function Base.display_error(io::IO, er, bt)
                @debug "in: display_error" er typeof(er) fieldnames(typeof(er)) bt
                # if er isa LoadError
                #     Base.showerror(io, er.error, bt)
                # end
            end
            
            
            # --------------------------- handle backtrace only -------------------------- #
            """
            Re-define the Base module function to print a nicely formatted stack trace.
            """

            function Base.show_backtrace(io::IO, t::Vector) 
                @debug "in: show_backtrace" t
            end
        end
    end
end