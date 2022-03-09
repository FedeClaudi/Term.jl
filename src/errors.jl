module errors
include("_errors.jl")

import Base: InterpreterIP, show_method_candidates, ExceptionStack

import Term:
    theme, highlight, reshape_text, read_file_lines, load_code_and_highlight, split_lines
import Term.style: apply_style
import ..panel: Panel, TextBox
import ..renderables: RenderableText
import ..layout: hLine, Spacer
import ..consoles: Console
import ..measure: Measure

export install_stacktrace

const ErrorsExplanations = Dict(
    ArgumentError => "The parameters to a function call do not match a valid signature.",
    AssertionError => "comes up when an assertion's check fails (e.g., `@assert 1==2`)",
    BoundsError => "comes up when trying to acces a container at invalid position (e.g., a string a='abcd' with 4 characters cannot be accessed as a[5]).",
    DimensionMismatch => "comes up when trying to perform an operation on objects which don't have matching dimensionality (e.g., summing matrixes of different size).",
    DivideError => "comes up when attempting integer division with 0 as denominator. [blue]2/0=Inf[/blue] is okay, but [orange1]div(2, )[/orange1] will give an error",
    DomainError => "comes up when the argument to a function is outside its domain (e.g., √(-1))",
    ErrorException => "is a generic error type",
    KeyError => "comes up when attempting to access a non-existing [blue]Dict[/blue] key.",
    InexactError => "comes up when a type cannot exactly be converted to another (e.g. Int(2.5) cannot convert Float64 to Int64, but Int(round(2.5)) will work)",
    LoadError => "occurs when another comes up while evaluating 'include', 'require' or 'using' statements",
    MethodError => "comes up when to method can be found with a given name and for a given set of argument types.",
    StackOverflowError => "usually comes up when functions call each other recursively.",
    TypeError => "is a type assertion failure, or calling an intrinsic function with an incorrect argument type.",
    UndefKeywordError => "comes up when a function has a keyword argument with no default value and no value is passed to a function call",
    UndefVarError => "comes up when a variable is used which is either not defined, or, which is not visible in the current variables scope (e.g.: variable defined in function A and used in function B)",
)

_width() = min(Console(stderr).width, 120)

# ----------------------- error type specific messages ----------------------- #

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
    main_msg = "Attempted to access $(_highlight_with_type(er.a)) at index $(_highlight_with_type(er.i))"

    additional_msg = ""

    if isdefined(er, :a)
        if er.a isa AbstractString
            nunits = ncodeunits(er.a)
            additional_msg = "S\ntring has $nunits codeunits, $(length(er.a)) characters."
        end
    else
        additional_msg = "\n[red]Variable is not defined!.[/red]"
    end
    return main_msg, additional_msg
end

# ! Domain ERROR
function error_message(io::IO, er::DomainError)
    # @info "err exceprion" er fieldnames(DomainError) er.val
    # msg = split(er.msg, " around ")[1]
    return er.msg, "\nThe invalid value is: $(_highlight_with_type(er.val))."
end

# ! DimensionMismatch
function error_message(io::IO, er::DimensionMismatch)
    return _highlight_numbers(er.msg), ""
end

# ! DivideError
function error_message(io::IO, er::DivideError)
    return "Attempted integer division by [blue]0[/blue]", ""
end

# ! EXCEPTION ERROR
function error_message(io::IO, er::ErrorException)
    # @info "err exceprion" er fieldnames(ErrorException) er.msg
    msg = split(er.msg, " around ")[1]
    return msg, ""
end

# !  KeyError
function error_message(io::IO, er::KeyError)
    # @info "err KeyError" er fieldnames(KeyError)
    msg = "Key $(_highlight_with_type(er.key)) not found!"
    return msg, ""
end

# ! InexactError
function error_message(io::IO, er::InexactError)
    # @info "load error message"  fieldnames(InexactError)
    msg = "Cannot convert $(_highlight_with_type(er.val)) to type [$(theme.type)]$(er.T)[/$(theme.type)]"
    subm = "\nConversion error in function: $(_highlight(er.func))"
    return msg, subm
end

# ! LoadError
function error_message(io::IO, er::LoadError)
    # @info "load error message"  fieldnames(LoadError)
    msg = "At [grey62 underline]$(er.file)[/grey62 underline] line [bold]$(er.line)"
    subm = "The cause is an error of type: [bright_red]$(string(typeof(er.error)))"
    return msg, subm
end

# ! METHOD ERROR
_method_regexes = [r"!Matched+[:a-zA-Z]*\{+[a-zA-Z\s \,]*\}", r"!Matched+[:a-zA-Z]*"]
function error_message(io::IO, er::MethodError; kwargs...)
    # get main error message
    _args = join([string(ar) * _highlight(typeof(ar)) for ar in er.args], "\n      ")
    fn_name = "$(_highlight(string(er.f)))"
    main_line = "No method matching $fn_name with aguments:\n      " * _args

    # get recomended candidates
    _candidates = split(sprint(show_method_candidates, er; context = io), "\n")
    candidates::Vector{String} = []

    for can in _candidates[3:(end - 1)]
        fun, file = split(can, " at ")
        name, args = split(fun, "("; limit = 2)
        # name = "[red]$name[/red]"

        for regex in _method_regexes
            for match in collect(eachmatch(regex, args))
                args = replace(
                    args, match.match => "[dim red]$(match.match[9:end])[/dim red]"
                )
            end
        end

        file, lineno = split(file, ":")

        # println(RenderableText(name, "red"))
        push!(candidates, fn_name * "(" * args)
        push!(candidates, "[dim]$file [bold dim](line: $lineno)[/bold dim][/dim]\n")
    end
    candidates =
        length(candidates) == 0 ? ["[dim]no candidate method found[/dim]"] : candidates

    return main_line * "\n",
    Panel(
        "\n" * join(candidates, "\n");
        width = _width() - 10,
        title = "closest candidates",
        title_style = "yellow",
        style = "blue dim",
    )
end

# ! StackOverflowError
function error_message(io::IO, er::StackOverflowError)
    return "Stack overflow error: too many function calls.", ""
end

# ! TYPE ERROR
function error_message(io::IO, er::TypeError)
    # @info "type err" er fieldnames(typeof(er)) er.func er.context er.expected er.got
    # var = string(er.var)
    msg = "In `[$(theme.emphasis_light) italic]$(er.func)` > `$(er.context)[/$(theme.emphasis_light) italic]` got"
    msg *= " [orange1 bold]$(er.got)[/orange1 bold][$(theme.type)](::$(typeof(er.got)))[/$(theme.type)] but expected argument of type"
    msg *= " [$(theme.type)]::$(er.expected)[/$(theme.type)]"
    return msg, ""
end

# ! UndefKeywordError
function error_message(io::IO, er::UndefKeywordError)
    # @info "UndefKeywordError" er er.var typeof(er.var) fieldnames(typeof(er.var))
    var = string(er.var)
    return "Undefined function keyword argument: '$(_highlight(er.var))'.", ""
end

# ! UNDEFVAR ERROR
function error_message(io::IO, er::UndefVarError)
    # @info "undef var error" er er.var typeof(er.var)
    var = string(er.var)
    return "Undefined variable '$(_highlight(er.var))'.", ""
end

# ! STRING INDEX ERROR
function error_message(io::IO, er::StringIndexError)
    # @info er typeof(er) fieldnames(typeof(er)) 
    m1 = "attempted to access a String at index $(er.index)\n"
    return m1, ""
end

# ! catch all other errors
function error_message(io::IO, er)
    @debug "Error message type doesnt have a specialized method!" er typeof(er) fieldnames(
        typeof(er)
    )
    if hasfield(typeof(er), :error)
        # @info "nested error" typeof(er.error)
        m1, m2 = error_message(io, er.error)
        msg = "\n[bold red]LoadError:[/bold red]\n" * m1
    else
        msg = if hasfield(typeof(er), :msg)
            er.msg
        else
            "no message for error of type $(typeof(er)), sorry."
        end
        m2 = ""
    end
    return msg, m2
end

# ---------------------------------------------------------------------------- #
#                              INSTALL STACKTRACE                              #
# ---------------------------------------------------------------------------- #
function install_stacktrace()
    @eval begin

        # ---------------------------- handle load errors ---------------------------- #
        function Base.showerror(io::IO, er::LoadError, bt; backtrace = true)
            print("\n")
            println(hLine(_width(), "[bold red]LoadError[/bold red]"; style = "dim red"))
            Base.display_error(io, er, bt)

            return Base.showerror(io, er.error, bt; backtrace = true)
        end

        """
        prints a line to mark te start of the error followed
        by the error's stack trace
        """
        function Base.showerror(io::IO, er, bt; backtrace = true)
            ename = string(typeof(er))
            print(hLine(_width(), "[bold red]$ename[/bold red]"; style = "dim red"))

            try
                stack = style_backtrace(io, bt)
                print(stack)
            catch stack_error
                @warn "failed to generate stack trace" er stack_error
                println.(style_stacktrace_simple(bt))
            end
        end

        # # ------------------ handle all other errors (no backtrace) ------------------ #
        """
        Re-define Base module function. Prints a nicely formatted error message.
        """
        function Base.display_error(io::IO, er, bt)
            try
                err, err_msg = style_error(io, er)
                println(err / err_msg)
            catch styling_error
                @error "Failed to generate styled error message" styling_error stacktrace()

                println(apply_style("Original error: [bright_red]$(string(er))"))
            end
        end
    end
end
end
