module stacktrace

    import Base: InterpreterIP, show_method_candidates, ExceptionStack

    import Term: theme, highlight, rehsape_text
    import ..panel: Panel, TextBox
    import ..renderables: RenderableText
    import ..layout: hLine

    export install_stacktrace

    const ErrorsExplanations = Dict(
        UndefVarError => "comes up when a variable is used which is either not defined, or, which is not visible in the current variables scope (e.g.: variable defined in function A and used in function B)",
        MethodError => "comes up when to method can be found with a given name and for a given set of argument types.",
        BoundsError => "comes up when trying to acces a container at invalid position (e.g. a string a='abcd' with 4 characters cannot be accessed as a[5]).",
    )
    
    IS_LOAD_ERROR = false

    _highlight(x::Union{Symbol, AbstractString}) = "[bold salmon1 underline]$x[/bold salmon1 underline]"
    _highlight(x::Number) = "[bold blue]$x[/bold blue]"
    _highlight(x::DataType)= "[$(theme.type) dim]::$(x)[/$(theme.type) dim]"

    _highlight(x) = @info "highlighting misterious object" x typeof(x)


    # --------------------------------- messages --------------------------------- #
    # ! UNDEFVAR ERROR
    error_message(io::IO, er::UndefVarError) =  "Undefined variable '$(_highlight(er.var))'.", ""

    # ! METHOD ERROR
    _method_regexes = [
        r"!Matched+[:a-zA-Z]*\{+[a-zA-Z\s \,]*\}",    
        r"!Matched+[:a-zA-Z]*",
    ]
    function error_message(io::IO, er::MethodError; kwargs...)
        # @info "er" er.f er.args er.world er.args[1] typeof(er.args[1])

        # get main error message
        _args = join([string(ar)*_highlight(typeof(ar)) for ar in er.args], ", ")
        main_line = "No method matching $(_highlight(string(er.f)))(" * _args * ")"

        # get recomended candidates
        _candidates = split(sprint(show_method_candidates, er; context=io), "\n")
        candidates::Vector{String} = []

        for can in _candidates[3:end-1]
            fun, file = split(can, " at ")
            name, args = split(fun, "(", limit=2)
            name = "[red]$name[/red]"

            for regex in _method_regexes
                for match in collect(eachmatch(regex, args))
                    args = replace(args, match.match=>"[dim red]$(match.match[9:end])[/dim red]")
                end
            end

            file, lineno = split(file, ":")

            println(RenderableText(name, "red"))
            push!(candidates, "   " * name * "("*args)
            push!(candidates, "[dim]$file [bold dim](line: $lineno)[/bold dim][/dim]\n")

        end
        candidates = length(candidates) == 0 ?  ["[dim]no candidate method found[/dim]"] : candidates

        return main_line * "\n",  Panel(
            "\n" * join(candidates, "\n"),
            width=76,
            title="closest candidates",
            title_style="yellow",
            style="blue dim",
            )
    end

    # ! BOUNDS ERROR
    function error_message(io::IO, er::BoundsError)::String
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


    # ! string index error
    function error_message(io::IO, er::StringIndexError)
        # @info er typeof(er) fieldnames(typeof(er)) 
        m1 = "attempted to access a String at index $(er.index)\n"
        # m2 = "String: [light_green]$(er.string)[/light_green]"
        # println(m1 * m2)
        return m1, ""
    end

    # ! catch all other errors
    function error_message(io::IO, er) 
        @info er typeof(er) fieldnames(typeof(er)) 
        return "no message for error of type $(typeof(er)), sorry.", ""
    end


    # ----------------------------- styling functions ---------------------------- #
    function style_error(io::IO, er)
        width = 90
            
        if haskey(ErrorsExplanations, typeof(er))
            info_msg = ErrorsExplanations[typeof(er)]
        else
            info_msg = "no additional info available."
        end
        
        main_message, message = error_message(io, er)
        return Panel(
                main_message,
                message,
                hLine(width-4; style="red dim"),
                RenderableText("[grey89 dim][bold red dim]$(typeof(er)):[/bold red dim] " * info_msg * "[/grey89 dim]"; width=width-4),
                title="ERROR: [bold indian_red]$(typeof(er))[/bold indian_red]",
                title_style="red",
                style = "dim red",
                width=width,
                title_justify=:center,
            ),  RenderableText("\n[bold indian_red]$(typeof(er)):[/bold indian_red] $main_message")
    end

    function style_backtrace(io::IO, t::Vector)
        width = 90

        # create text
        stack_lines::Vector{String} = []
        for (n, frame) in enumerate(t)
            if typeof(frame) ∉ (Ptr{Nothing}, InterpreterIP)

                func_line = "[light_yellow3]($n)[/light_yellow3] [sky_blue3]$(frame.func)[/sky_blue3]"
                file_line = "       [dim]$(frame.file):$(frame.line) [bold dim](line: $(frame.line))[/bold dim][/dim]"
                push!(stack_lines, func_line * "\n" * file_line * "\n" )
            # else
            #     @info "skipped frame" frame
            end
        end
    
        # highlight offending line
        if length(stack_lines) > 0
            error_line = Panel(
                stack_lines[1],
                title="error in",
                width=90-8,
                style="dim blue",
                title_style="yellow",
                )


            above = TextBox(
                stack_lines[2:end-1],
                width=width-8
            )
            
            offending = Panel(
                stack_lines[end][35:end],
                title="caused by",
                width=90-8,
                style="dim blue",
                title_style="yellow",
                )

            stack = error_line / above / offending
        else
            stack = "[dim]No stack trace[/dim]"
        end

        # create output
        return Panel(
                stack,
                title="StackTrace",
                style="yellow dim",
                title_style="yellow",
                title_justify=:center,
                width=width
            )
        
    end



    # ---------------------------------------------------------------------------- #
    #                              INSTALL TRACESTACK                              #
    # ---------------------------------------------------------------------------- #
    function install_stacktrace()
        @eval begin


            # ---------------------------- handle load errors ---------------------------- #
            function Base.showerror(io::IO, ex::LoadError, bt; backtrace=true)
                IS_LOAD_ERROR = true
                println("\n")

                stack = style_backtrace(io, bt)
                err, err_msg = style_error(io, ex.error)
            
                # print or stack based on terminal size
                if displaysize(io)[2] >= 180
                    println((stack * err) / err_msg) 
                else
                    println(stack / err / err_msg)
                end

            end

            # ------------------ handle all other errors (no backtrace) ------------------ #
            """
            Re-define Base module function. Prints a nicely formatted error message, but only
            if the error wasn't nested in a LoadError. In that case `Base.showerror(io::IO, ex::LoadError, bt; backtrace=true)`
            handles all the printing and printing the message here would cause a duplicate.
            """

            function Base.display_error(io::IO, er, bt)
                @warn "in: display_error" IS_LOAD_ERROR er bt
            #     if !IS_LOAD_ERROR
                    
            # #         stack = style_backtrace(io, bt)
            # #         err = style_error(io, ex.error)
            #         println(style_error(io, er))
            # #         # println(style_error(io, er))
            # #         println(stack / err)
            #     end
            end
            
            
            # --------------------------- handle backtrace only -------------------------- #
            """
            Re-define the Base module function to print a nicely formatted stack trace.
            """

            function Base.show_backtrace(io::IO, t::Vector) 
                @warn "in: show_backtrace" io t
                # println(style_backtrace(io, t))              
            end
        end
    end
end