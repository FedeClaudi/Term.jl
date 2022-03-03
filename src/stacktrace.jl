module stacktrace
    import Base: InterpreterIP, show_method_candidates, ExceptionStack

    import Term: theme, highlight, rehsape_text, read_file_lines, load_code_and_highlight, split_lines
    import Term.style: apply_style
    import ..panel: Panel, TextBox
    import ..renderables: RenderableText
    import ..layout: hLine
    import ..consoles: Console

    export install_stacktrace

    const ErrorsExplanations = Dict(
        AssertionError  => "comes up when an assertion's check fails. For example `@assert 1==2` will throw an AssertionError",
        BoundsError     => "comes up when trying to acces a container at invalid position (e.g. a string a='abcd' with 4 characters cannot be accessed as a[5]).",
        ErrorException  => "is a generic error type",
        MethodError     => "comes up when to method can be found with a given name and for a given set of argument types.",
        UndefVarError   => "comes up when a variable is used which is either not defined, or, which is not visible in the current variables scope (e.g.: variable defined in function A and used in function B)",
    )
    
    IS_LOAD_ERROR = false
    _width() = min(Console(stderr).width, 120)

    _highlight(x::Union{Symbol, AbstractString}) = "[bold salmon1 underline]$x[/bold salmon1 underline]"
    _highlight(x::Number) = "[bold blue]$x[/bold blue]"
    _highlight(x::DataType) = "[$(theme.type) dim]::$(x)[/$(theme.type) dim]"
    _highlight(x::UnitRange) = _highlight(string(x))

    function _highlight(x)
        @info "highlighting misterious object" x typeof(x)
        return _highlight(string(x))
    end


    # --------------------------------- messages --------------------------------- #

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
            width=_width() - 10,
            title="closest candidates",
            title_style="yellow",
            style="blue dim",
            )
    end

    # ! UNDEFVAR ERROR
    error_message(io::IO, er::UndefVarError) =  "Undefined variable '$(_highlight(er.var))'.", ""

    

    # ! STRING INDEX ERROR
    function error_message(io::IO, er::StringIndexError)
        # @info er typeof(er) fieldnames(typeof(er)) 
        m1 = "attempted to access a String at index $(er.index)\n"
        return m1, ""
    end



    # ! catch all other errors
    function error_message(io::IO, er) 
        @info er typeof(er) fieldnames(typeof(er)) 
        msg = hasfield(typeof(er), :msg) ? er.msg : "no message for error of type $(typeof(er)), sorry."
        return msg, ""
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
        return Panel(
            "[#FFCC80]" * main_message * "[/#FFCC80]",
                message,
                hLine(WIDTH-4; style="red dim"),
                RenderableText("[grey89 dim][bold red dim]$(typeof(er)):[/bold red dim] " * info_msg * "[/grey89 dim]"; width=WIDTH-4),
                title="ERROR: [bold indian_red]$(typeof(er))[/bold indian_red]",
                title_style="red",
                style = "dim red",
                width=WIDTH,
                title_justify=:center,
            ),  RenderableText("\n[bold indian_red]$(typeof(er)):[/bold indian_red] $main_message")
    end



    function backtrace_subpanel(line::String, WIDTH::Int, title::String)

        # get path to file and line number
        file = split(split_lines(line)[2], " [bold dim]")[1][13:end]
        file, lineno = split(file, ":")
        lineno = parse(Int, lineno)
        
        # read and highlight text
        code = load_code_and_highlight(file, lineno; δ=3)

        return Panel(
            "\n",
            line,
            TextBox(code, width=WIDTH-6),
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
            if typeof(frame) ∉ (Ptr{Nothing}, InterpreterIP)
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

            # @info 1 error_line
            if length(stack_lines) > 3
                above = TextBox(
                    stack_lines[2:end-1],
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

            # @info 2 above
            offending = backtrace_subpanel(stack_lines[end], WIDTH, "caused by")

            
            Panel(
                stack_lines[end],
                title="caused by",
                width=WIDTH-12,
                style="dim blue",
                title_style="yellow",
                )
            # @info 3 offending

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
                width=WIDTH
            )
        
    end

    # ---------------------------------------------------------------------------- #
    #                              INSTALL TRACESTACK                              #
    # ---------------------------------------------------------------------------- #
    function install_stacktrace()
        @eval begin

            # ---------------------------- handle load errors ---------------------------- #
            function Base.showerror(io::IO, ex::LoadError, bt; backtrace=true)
                try
                    println("\n")
                    # @info "loaderror" ex.error 
                    IS_LOAD_ERROR = true

                    stack = style_backtrace(io, bt)
                    # @info "error stack ready"


                    err, err_msg = style_error(io, ex.error)
                    # @info "error message ready" stack err err_msg
                
                    # print or stack based on terminal size
                    println(stack / err / err_msg)
                catch err
                    @warn "Failed to render error $ex" ex bt err
                end

            end

            # ------------------ handle all other errors (no backtrace) ------------------ #
            """
            Re-define Base module function. Prints a nicely formatted error message, but only
            if the error wasn't nested in a LoadError. In that case `Base.showerror(io::IO, ex::LoadError, bt; backtrace=true)`
            handles all the printing and printing the message here would cause a duplicate.
            """

            function Base.display_error(io::IO, er, bt)
                @debug "in: display_error" IS_LOAD_ERROR er bt
            end
            
            
            # --------------------------- handle backtrace only -------------------------- #
            """
            Re-define the Base module function to print a nicely formatted stack trace.
            """

            function Base.show_backtrace(io::IO, t::Vector) 
                @debug "in: show_backtrace" io t
            end
        end
    end
end