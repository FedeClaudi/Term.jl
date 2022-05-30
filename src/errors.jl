module Errors

import Base: show_method_candidates, ExceptionStack, InterpreterIP

import Term: highlight, truncate

import ..Layout: hLine, rvstack, cvstack, rvstack, vstack, vLine, Spacer, hstack, lvstack
import ..Renderables: RenderableText, AbstractRenderable
import ..Panels: Panel

export install_term_stacktrace

include("_errors.jl")

const ErrorsExplanations = Dict(
    ArgumentError => "The parameters to a function call do not match a valid signature.",
    AssertionError => "comes up when an assertion's check fails (e.g., `@assert 1==2`)",
    BoundsError => "comes up when trying to acces a container at invalid position (e.g., a string a='abcd' with 4 characters cannot be accessed as a[5]).",
    DimensionMismatch => "comes up when trying to perform an operation on objects which don't have matching dimensionality (e.g., summing matrixes of different size).",
    DivideError => "comes up when attempting integer division with 0 as denominator. {blue}2/0=Inf{/blue} is okay, but {orange1}div(2, ){/orange1} will give an error",
    DomainError => "comes up when the argument to a function is outside its domain (e.g., √(-1))",
    ErrorException => "is a generic error type",
    KeyError => "comes up when attempting to access a non-existing {blue}Dict{/blue} key.",
    InexactError => "comes up when a type cannot exactly be converted to another (e.g. Int(2.5) cannot convert Float64 to Int64, but Int(round(2.5)) will work)",
    LoadError => "occurs when another comes up while evaluating 'include', 'require' or 'using' statements",
    MethodError => "comes up when to method can be found with a given name and for a given set of argument types.",
    StackOverflowError => "usually comes up when functions call each other recursively.",
    TypeError => "is a type assertion failure, or calling an intrinsic function with an incorrect argument type.",
    UndefKeywordError => "comes up when a function has a keyword argument with no default value and no value is passed to a function call",
    UndefVarError => "comes up when a variable is used which is either not defined, or, which is not visible in the current variables scope (e.g.: variable defined in function A and used in function B)",
)

_width() = min(console_width(stderr), 100)

# ----------------------- error type specific messages ----------------------- #

# ! ARGUMENT ERROR
error_message(er::ArgumentError) = er.msg, ""

# ! ASSERTION ERROR
error_message(er::AssertionError) = return er.msg, ""

# ! BOUNDS ERROR
function error_message(er::BoundsError)
    # @info "bounds error" er fieldnames(typeof(er))
    main_msg = "Attempted to access `$(er.a)` at index $(er.i)"

    additional_msg = ""

    if isdefined(er, :a)
        if er.a isa AbstractString
            nunits = ncodeunits(er.a)
            additional_msg = "S\ntring has $nunits codeunits, $(length(er.a)) characters."
        end
    else
        additional_msg = "\n{red}Variable is not defined!.{/red}"
    end
    return main_msg, additional_msg
end

# ! Domain ERROR
function error_message(er::DomainError)
    # @info "err exceprion" er fieldnames(DomainError) er.val
    # msg = split(er.msg, " around ")[1]
    return er.msg, "\nThe invalid value is: $(er.val)."
end

# ! DimensionMismatch
error_message(er::DimensionMismatch) = er.msg, ""

# ! DivideError
error_message(er::DivideError) = "Attempted integer division by {bold}0{/bold}", ""

# ! EXCEPTION ERROR
function error_message(er::ErrorException)
    # @info "err exceprion" er fieldnames(ErrorException) er.msg
    msg = split(er.msg, " around ")[1]
    return msg, ""
end

# !  KeyError
function error_message(er::KeyError)
    # @info "err KeyError" er fieldnames(KeyError)
    msg = "Key `$(er.key)` not found!"
    return msg, ""
end

# ! InexactError
function error_message(er::InexactError)
    # @info "load error message"  fieldnames(InexactError)
    msg = "Cannot convert $(er.val) to type ::$(er.T)"
    subm = "\nConversion error in function: $(er.func)"
    return msg, subm
end

# ! LoadError
function error_message(er::LoadError)
    # @info "load error message"  fieldnames(LoadError)
    msg = "At {grey62 underline}$(er.file){/grey62 underline} line {bold}$(er.line){/bold}"
    subm = "The cause is an error of type: {bright_red}$(string(typeof(er.error)))"
    return msg, subm
end

# ! METHOD ERROR
method_error_regex = r"(?<group>\!Matched\:\:(\w|\.)+)"
function method_error_candidate(fun, candidate)
    # highlight non-matched types
    candidate = replace(
        candidate,
        method_error_regex => SubstitutionString("{red}" * s"\g<0>" * "{/red}"),
    )
    # remove
    candidate = replace(candidate, "!Matched" => "")

    # highlight fun
    candidate = replace(candidate, fun => "{bold yellow}$(fun){/bold yellow}")
    return candidate
end

function error_message(er::MethodError; kwargs...)
    # @info "method error" er fieldnames(MethodError) er.f er.args er.world
    # get main error message
    _args = join(
        map(
            a ->
                "   {dim bold}($(a[1])){/dim bold} $(truncate(highlight("::"*string(typeof(a[2]))), 30))",
            enumerate(er.args),
        ),
        "\n",
    )
    fn_name = "$(string(er.f))"
    main_line = "No method matching `$fn_name` with arguments types:" / _args

    # get recomended candidates
    _candidates = split(sprint(show_method_candidates, er), "\n")[3:(end - 1)]
    if length(_candidates) > 0
        _candidates = map(c -> split(c, " at ")[1], _candidates)
        candidates = map(c -> method_error_candidate(fn_name, c), _candidates)
        main_line =
            main_line / "" / "Alternative candidates:" /
            lvstack(RenderableText.(candidates))
    else
        main_line = main_line / " " / "{dim}No alternative candidates found"
    end

    return string(main_line), ""
end

# ! StackOverflowError
error_message(er::StackOverflowError) = "Stack overflow error: too many function calls.", ""

# ! TYPE ERROR
function error_message(er::TypeError)
    # @info "type err" er fieldnames(typeof(er)) er.func er.context er.expected er.got
    # var = string(er.var)
    msg = "In `$(er.func)` > `$(er.context)` got"
    msg *= " {orange1 bold}$(er.got){/orange1 bold}(::$(typeof(er.got))) but expected argument of type ::$(er.expected)"
    return msg, ""
end

# ! UndefKeywordError
function error_message(er::UndefKeywordError)
    # @info "UndefKeywordError" er er.var typeof(er.var) fieldnames(typeof(er.var))
    var = string(er.var)
    return "Undefined function keyword argument: `$(er.var)`.", ""
end

# ! UNDEFVAR ERROR
function error_message(er::UndefVarError)
    # @info "undef var error" er er.var typeof(er.var)
    var = string(er.var)
    return "Undefined variable `$(er.var)`.", ""
end

# ! STRING INDEX ERROR
function error_message(er::StringIndexError)
    # @info er typeof(er) fieldnames(typeof(er)) 
    m1 = "attempted to access a String at index $(er.index)\n"
    return m1, ""
end

# ! catch all other errors
function error_message(er)
    # @debug "Error message type doesnt have a specialized method!" er typeof(er) fieldnames(
    #     typeof(er)
    # )
    if hasfield(typeof(er), :error)
        # @info "nested error" typeof(er.error)
        m1, m2 = error_message(er.error)
        msg = "\n{bold red}LoadError:{/bold red}\n" * m1
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
function install_term_stacktrace(; reverse_backtrace::Bool = true, max_n_frames::Int = 30)
    @eval begin
        function Base.showerror(io::IO, er, bt; backtrace = true)
            (length(bt) == 0 && !isa(er, StackOverflowError)) && return nothing
            try
                println("\n")
                ename = string(typeof(er))
                error =
                    hLine("{default bold red}$ename{/default bold red}"; style = "dim red")
                if length(bt) > 0
                    rendered_bt = render_backtrace(
                        bt;
                        reverse_backtrace = $(reverse_backtrace),
                        max_n_frames = $(max_n_frames),
                    )
                    error /= rendered_bt
                    W = rendered_bt.measure.w
                else
                    W = 88
                end
                err, _ = error_message(er)
                msg =
                    "" / Panel(
                        "{#aec2e8}$(err){/#aec2e8}";
                        width = W,
                        title = "{bold red default underline}$(typeof(er)){/bold red default underline}",
                        padding = (2, 2, 1, 1),
                        style = "dim red",
                        title_justify = :center,
                    )
                error /= msg
                print(error)
            catch err
                @error "ERROR: " exception = err
                # @warn "Term.jl: failed to render error message" err
                # Base.showerror(io, er)
            end
        end
    end
end

end
