"""
    _highlight(x)

Apply style to `x` based on its type.
"""
function _highlight end

_highlight(x::Union{Symbol,AbstractString}) = "[$(theme.symbol)]$x[/$(theme.symbol)]"
_highlight(x::Number) = "[$(theme.number)]$x[/$(theme.number)]"
_highlight(x::DataType) = "[$(theme.type) dim]::$(x)[/$(theme.type) dim]"
_highlight(x::UnitRange) = _highlight(string(x))
function _highlight(x::Union{AbstractArray,AbstractVector,AbstractMatrix})
    return "[$(theme.number)]$x[/$(theme.number)]"
end
_highlight(x::Function) = "[$(theme.function)]$x[/$(theme.function)]"

function _highlight(x)
    return _highlight(string(x))
end

"""
    _highlight_with_type(x)

Apply style to x and and mark its type.
"""
_highlight_with_type(x) = "$(_highlight(x))$(_highlight(typeof(x)))"

"""
    _highlight_numbers(x::AbstractString) 

Add style to each number in a string
"""
function _highlight_numbers(x::AbstractString)
    for match in collect(eachmatch(r"[0-9]", x))
        x = replace(x, match.match => "[blue]$(match.match)[/blue]")
    end
    return x
end

"""
    style_error(io::IO, er)

Create a style error panel.

Creates a `Panel` with an error message and optional hints.
"""
function style_error(io::IO, er)
    if haskey(ErrorsExplanations, typeof(er))
        info_msg = ErrorsExplanations[typeof(er)]
    else
        info_msg = nothing
    end

    WIDTH = _width()
    main_message, message = error_message(io, er) 
    # @info "Got styled error" main_message info_msg isnothing(info_msg) typeof(message)

    # create panel and text
    if !isnothing(info_msg) &&  Measure(message).w > 0
        panel = Panel(
            main_message / message,
            hLine(WIDTH - 4; style = "red dim"),
            RenderableText(
                "[bold yellow italic underline]hint:[/bold yellow italic underline] [bright_red]$(typeof(er))[/bright_red] " *
                info_msg;
                width = WIDTH - 4,
            );
            title = "ERROR: [bold indian_red]$(typeof(er))[/bold indian_red]",
            title_style = "red",
            style = "dim red",
            width = WIDTH,
            title_justify = :left,
        )
    else
        panel = Panel(
            main_message;
            title = "ERROR: [bold indian_red]$(typeof(er))[/bold indian_red]",
            title_style = "red",
            style = "dim red",
            width = WIDTH,
            title_justify = :left,
        )
    end
    text = RenderableText(
        "\n[bold indian_red]$(typeof(er)):[/bold indian_red] $main_message"
    )

    return panel, text
end

"""
    backtrace_subpanel(line::String, WIDTH::Int, title::String)

Create a subpanel for stacktrace, showing source code.
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
        code = load_code_and_highlight(file, lineno; δ = 2)
        if length(code) > 0
            code = TextBox(code; width = WIDTH - 26)
            code = Spacer(8, code.measure.h) * code
        end
    catch SystemError  # file not found
        # @warn "Failed to get code"
        code = ""
    end

    # @info "line&code" line code
    panel = Panel(
        "\n",
        chomp(line),
        code;
        title = title,
        width = :fit,
        style = "dim blue",
        title_style = "bold bright_yellow",
    )
    # @info "Created backtrace subpanel"
    return panel
end

"""
    style_backtrace(io::IO, t::Vector)

Create a Panel with styled error backtrace information.
"""
function style_backtrace(io::IO, t::Vector)
    # @info "styling backtrace"
    WIDTH = _width()

    # create text
    stack_lines::Vector{String} = []
    for (n, frame) in enumerate(t)
        if typeof(frame) ∉ (Ptr, InterpreterIP)
            func_line = "[light_yellow3]($n)[/light_yellow3] [sky_blue3]$(frame.func)[/sky_blue3]"
            file_line = "       [dim]$(frame.file):$(frame.line) [bold dim](line: $(frame.line))[/bold dim][/dim]"
            push!(stack_lines, func_line * "\n" * file_line)
        end
    end

    # trim excedingly long stack traces
    if length(stack_lines) > 10
        stack_lines = vcat(
            stack_lines[1:5],
            "\n[dim bright_blue]        ... skipped $(length(stack_lines)-11) levels in stack trace ...\n",
            stack_lines[(end - 5):end],
        )
    end

    # create layout
    # @info "creating stack panels" length(stack_lines)
    if length(stack_lines) > 0
        if length(stack_lines) > 1
            error_line = backtrace_subpanel(stack_lines[1], WIDTH - 8, "error in")
        else
            error_line = ""
        end

        # @info "error line ready" error_line length(stack_lines)
        if length(stack_lines) > 3
            above = TextBox(join(stack_lines[2:(end - 1)], "\n"); width = WIDTH - 8)
        elseif length(stack_lines) > 2
            above = TextBox(stack_lines[2]; width = WIDTH - 8)
        else
            above = ""
        end
        # @info "above ready"

        offending = backtrace_subpanel(stack_lines[end], WIDTH - 8, "caused by")
        # @info "offending ready" offending
        stack = error_line / above / offending
        # @info "stacked" stack
    else
        stack = "[dim]No stack trace[/dim]"
    end

    # create output
    # @info "creating panel"
    try
        panel = Panel(
            stack;
            title = "StackTrace",
            style = "yellow dim",
            title_style = "yellow",
            title_justify = :left,
            width = WIDTH,
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
    style_stacktrace_simple(stack::Vector)

Simply style a stacktrace. Just adding a miniumum of color.
"""
function style_stacktrace_simple(stack::Vector)
    lines::Vector{String} = []
    for (n, frame) in enumerate(stack)
        if typeof(frame) ∉ (Ptr.Ptr{Nothing}, InterpreterIP)
            push!(
                lines,
                apply_style(
                    "[bright_blue dim]($n)[/bright_blue dim] [yellow]$(frame.func)[/yellow] - [dim]$(line.file):$(line.line)[/dim]",
                ),
            )
        end
    end

    return join(lines, "\n")
end
