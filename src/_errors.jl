_highlight(x::Union{Symbol, AbstractString}) = "[$(theme.symbol)]$x[/$(theme.symbol)]"
_highlight(x::Number) = "[$(theme.number)]$x[/$(theme.number)]"
_highlight(x::DataType) = "[$(theme.type) dim]::$(x)[/$(theme.type) dim]"
_highlight(x::UnitRange) = _highlight(string(x))
_highlight(x::Union{AbstractArray, AbstractVector, AbstractMatrix}) =  "[$(theme.number)]$x[/$(theme.number)]"
_highlight(x::Function) = "[$(theme.function)]$x[/$(theme.function)]"

_highlight_with_type(x) = "$(_highlight(x))$(_highlight(typeof(x)))"

function _highlight_numbers(x::AbstractString) 
    for match in collect(eachmatch(r"[0-9]", x))
        x = replace(x, match.match=>"[blue]$(match.match)[/blue]")
    end
    return x
end


function _highlight(x)
    # @info "highlighting misterious object" x typeof(x)
    return _highlight(string(x))
end


function style_error(io::IO, er)
    if haskey(ErrorsExplanations, typeof(er))
        info_msg = ErrorsExplanations[typeof(er)]
    else
        info_msg = nothing
    end
    
    WIDTH = _width()
    main_message, message = error_message(io, er)
    # @info "Got styled error" er main_message info_msg

    # create panel and text
    if !isnothing(info_msg)
        panel = Panel(
            length(message) > 0 ? main_message / message : main_message,
            hLine(WIDTH-4; style="red dim"),
            RenderableText("[bold yellow italic underline]hint:[/bold yellow italic underline] [bright_red]$(typeof(er))[/bright_red] " * info_msg; width=WIDTH-4),
            title="ERROR: [bold indian_red]$(typeof(er))[/bold indian_red]",
            title_style="red",
            style = "dim red",
            width=WIDTH,
            title_justify=:left,
        )
    else
        panel = Panel(
            length(message) > 0 ? main_message / message : main_message,
            title="ERROR: [bold indian_red]$(typeof(er))[/bold indian_red]",
            title_style="red",
            style = "dim red",
            width=WIDTH,
            title_justify=:left,
        )
    end
    text = RenderableText("\n[bold indian_red]$(typeof(er)):[/bold indian_red] $main_message")

    return panel, text
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
        code = load_code_and_highlight(file, lineno; δ=2)
        if length(code) > 0
            code = TextBox(code, width=WIDTH-18)
            code = Spacer(8, code.measure.h) * code
        end
    catch SystemError  # file not found
        # @warn "Failed to get code"
        code = ""
    end

    return Panel(
        "\n",
        chomp(line),
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
            push!(stack_lines, func_line * "\n" * file_line )

        end
    end

    # trim exceedingly long stack traces
    if length(stack_lines) > 10
        stack_lines = vcat(
            stack_lines[1:5],
            "\n[dim bright_blue]        ... skipped $(length(stack_lines)-11) levels in stack trace ...\n",
            stack_lines[end-5:end],
        )
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
Simple styling of stack traces. Just adding a miniumum of color.
"""
function style_stacktrace_simple(stack::Vector)
    lines::Vector{String} = []
    for (n, frame) in enumerate(stack)
        if typeof(frame) ∉ (Ptr. Ptr{Nothing}, InterpreterIP)
            push!(lines, apply_style("[bright_blue dim]($n)[/bright_blue dim] [yellow]$(frame.func)[/yellow] - [dim]$(line.file):$(line.line)[/dim]"))
        end
    end

    return join(lines, "\n")
end