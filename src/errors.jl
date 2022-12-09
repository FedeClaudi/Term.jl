module Errors

import Base: show_method_candidates, ExceptionStack, InterpreterIP

import Term:
    highlight,
    str_trunc,
    reshape_text,
    load_code_and_highlight,
    default_stacktrace_width,
    escape_brackets,
    unescape_brackets,
    remove_markup,
    TERM_THEME,
    plural

import ..Style: apply_style
import ..Layout:
    hLine, rvstack, cvstack, rvstack, vstack, vLine, Spacer, hstack, lvstack, pad
import ..Renderables: RenderableText, AbstractRenderable
import ..Panels: Panel

export install_term_stacktrace

include("_errors.jl")

# ----------------------- error type specific messages ----------------------- #

# ! ARGUMENT ERROR
error_message(er::ArgumentError) = er.msg

# ! ASSERTION ERROR
error_message(er::AssertionError) = return er.msg

# ! BOUNDS ERROR
function error_message(er::BoundsError)
    # @info "bounds error" er fieldnames(typeof(er))
    obj = escape_brackets(string(typeof(er.a)))
    if er.a isa AbstractArray
        obj = "a `$obj` width shape $(string(size(er.a)))"
    end
    main_msg = "Attempted to access $(obj) at index $(er.i)"

    additional_msg = ""

    if isdefined(er, :a)
        if er.a isa AbstractString
            nunits = ncodeunits(er.a)
            additional_msg = "String has $nunits codeunits, $(length(er.a)) characters."
        end
    else
        additional_msg = "{red}Variable is not defined!.{/red}"
    end

    return highlight(main_msg) / additional_msg
end

# ! Domain ERROR
function error_message(er::DomainError)
    # @info "err exceprion" er fieldnames(DomainError) er.val
    # msg = split(er.msg, " around ")[1]
    return er.msg / "The invalid value is: $(er.val)." |> string
end

# ! DimensionMismatch
error_message(er::DimensionMismatch) = er.msg

# ! DivideError
error_message(er::DivideError) = "Attempted integer division by {bold}0{/bold}"

# ! EXCEPTION ERROR
function error_message(er::ErrorException)
    # @info "err exceprion" er fieldnames(ErrorException) er.msg
    msg = split(er.msg, " around ")[1]
    return msg
end

# !  KeyError
function error_message(er::KeyError)
    # @info "err KeyError" er fieldnames(KeyError)
    # key = truncate(string(er.key), 40)
    key = string(er.key)
    msg = "Key `$(key)` not found!"
    return msg
end

# ! InexactError
function error_message(er::InexactError)
    # @info "load error message"  fieldnames(InexactError)
    msg = "Cannot convert $(er.val) to type ::$(er.T)"
    subm = "Conversion error in function: $(er.func)"
    return msg / subm
end

# ! LoadError
function error_message(er::LoadError)
    theme = TERM_THEME[]
    # @info "load error message"  fieldnames(LoadError)
    msg = "At {$(theme.err_filepath) underline}$(er.file){/$(theme.err_filepath) underline} line {bold}$(er.line){/bold}"
    subm = "The cause is an error of type: {$(theme.err_errmsg)}$(string(typeof(er.error)))"
    return msg / subm
end

# ! METHOD ERROR
method_error_regex = r"(?<group>\!Matched\:\:(\w|\.)+)"
function method_error_candidate(fun, candidate)
    theme = TERM_THEME[]
    # highlight non-matched types
    candidate = replace(
        candidate,
        method_error_regex => SubstitutionString(
            "{$(theme.err_errmsg)}" * s"\g<0>" * "{/$(theme.err_errmsg)}",
        ),
    )
    # remove
    candidate = replace(candidate, "!Matched" => "")

    # highlight fun
    candidate = replace(candidate, string(fun) => "{$(theme.func)}$(fun){/$(theme.func)}")
    return candidate |> rstrip
end

function convert_error_message(er::MethodError, arg_types_param)
    T = Base.striptype(er.args[1])
    if T === nothing
        return "First argument to `convert` must be a Type, got $(er.args[1])"
    else
        p2 = arg_types_param[2]
        ok, not_ok = TERM_THEME[].emphasis, TERM_THEME[].warn
        a = T == p2 ? string(p2) : "{$ok bold}$p2{/$ok bold}"
        b = T == p2 ? string(T) : "{$not_ok bold}$T{/$not_ok bold}"
        return "Cannot `convert` an object of type: $(a) to an object of type $(b)"
    end
end

function handle_methoderror_special_cases(er, f, ft, arg_types_param, is_arg_types)
    # handle failed conversions
    if f === Base.convert && length(arg_types_param) == 2 && !is_arg_types
        return convert_error_message(er, arg_types_param)
    elseif f === Base.mapreduce_empty || f === Base.reduce_empty
        return "reducing over an empty collection is not allowed; consider supplying `init` to the reducer"
    elseif isempty(methods(f)) && isa(f, DataType) && isabstracttype(f)
        return "no constructors have been defined for $f"
    elseif isempty(methods(f)) && !isa(f, Function) && !isa(f, Type)
        return "objects of type ", ft, " are not callable"
    end
    # no edge case detect, return nothign
    return nothing
end

function error_message(er::MethodError; kwargs...)
    f = er.f
    ft = typeof(f)
    kwargs = ()
    is_arg_types = isa(er.args, DataType)
    arg_types = (is_arg_types ? er.args : Base.typesof(er.args...))::DataType
    arg_types_param::Base.SimpleVector = arg_types.parameters

    # handle calls kwcall
    args = er.args
    if length(args) > 1 && args[1] isa NamedTuple && contains(string(f), "##kw")
        f = (er.args::Tuple)[2]
        ft = typeof(f)

        arg_types_param = arg_types_param[3:end]
        kwargs = pairs(er.args[1])
        er = MethodError(f, er.args[3:(end::Int)])
    end

    # handle edge cases like failed calls to conver
    # @info "er" f ft arg_types_param kwargs
    msg = handle_methoderror_special_cases(er, f, ft, arg_types_param, is_arg_types)

    # if not an edge case, show signature of method call with args types
    emph = TERM_THEME[].emphasis
    sym = TERM_THEME[].symbol

    name =
        sprint(io -> Base.show_signature_function(io, isa(f, Type) ? Type{f} : typeof(f)))
    if isnothing(msg)
        msg = "No method matching {bold $(emph)}`$name`{/bold $(emph)} with arguments types:"
        args = join(map(a -> "::$(typeof(a))", er.args), ", ")
        !isempty(kwargs) && begin
            length(args) > 0 && (args *= "; ")
            args *= join(["{$sym}$k{/$sym}::$(typeof(v))" for (k, v) in kwargs], ", ")
        end
        msg /= highlight(args)
    end

    if (
        er.world != typemax(UInt) &&
        hasmethod(er.f, arg_types) &&
        !hasmethod(er.f, arg_types, world = er.world)
    )
        curworld = get_world_counter()
        msg /= "The applicable method may be too new: running in world age $(er.world), while current world is $(curworld)."
    end

    # get recomended candidates
    _candidates = split(sprint(show_method_candidates, er), "\n")[3:(end - 1)]

    if length(_candidates) > 0
        _candidates = map(c -> split(c, " at ")[1], _candidates)
        candidates = map(c -> method_error_candidate(name, c), _candidates)
        msg /=
            lvstack("", "Alternative candidates:", candidates...) |> string |> apply_style
    else
        msg /= " " / "{dim}No alternative candidates found"
    end

    return string(msg)
end

# ! StackOverflowError
error_message(er::StackOverflowError) = "Stack overflow error: too many function calls."

# ! TYPE ERROR
function error_message(er::TypeError)
    # @info "type err" er fieldnames(typeof(er)) er.func er.context er.expected er.got
    theme = TERM_THEME[]
    msg = "In `$(er.func)` > `$(er.context)` got"
    msg *= " {$(theme.emphasis_light)) bold}$(er.got){/$(theme.emphasis_light)) bold}(::$(typeof(er.got))) but expected argument of type ::$(er.expected)"
    return msg
end

# ! UndefKeywordError
function error_message(er::UndefKeywordError)
    # @info "UndefKeywordError" er er.var typeof(er.var) fieldnames(typeof(er.var))
    return "Undefined function keyword argument: `$(er.var)`."
end

# ! UNDEFVAR ERROR
function error_message(er::UndefVarError)
    # @info "undef var error" er er.var typeof(er.var)
    return "Undefined variable `$(er.var)`."
end

# ! STRING INDEX ERROR
function error_message(er::StringIndexError)
    # @info er typeof(er) fieldnames(typeof(er)) 
    m1 = "attempted to access a String at index $(er.index)\n"
    return m1
end

# ! catch all other errors
function error_message(er)
    # @debug "Error message type doesnt have a specialized method!" er typeof(er) fieldnames(
    #     typeof(er)
    # )
    theme = TERM_THEME[]
    if hasfield(typeof(er), :error)
        # @info "nested error" typeof(er.error)
        m1, _ = error_message(er.error)
        msg = "\n{bold $(theme.err_errmsg)}LoadError:{/bold $(theme.err_errmsg)}\n" * m1
    else
        msg = if hasfield(typeof(er), :msg)
            er.msg
        else
            # "no message for error of type $(typeof(er)), sorry."
            string(typeof(er))
        end
    end
    return msg
end

# ---------------------------------------------------------------------------- #
#                              INSTALL STACKTRACE                              #
# ---------------------------------------------------------------------------- #

"""
    install_term_stacktrace(; reverse_backtrace::Bool = true, max_n_frames::Int = 30)

Replace the default Julia stacktrace error stacktrace printing with Term's.

Term parses a `StackTrace` adding additional info and style before printing it out to the user.
The printed output consists of two parts:
    - a list of "frames": nested code points showing where the error occurred, the "Error Stack"
    - a message: generally the standard info message given by Julia but with addintional formatting
        option. 

Several options are provided to reverse the order in which the frames are shown (compared to
Julia's default ordering), hide extra frames when a large number is in the trace (e.g. Stack Overflow error)
and hide Base and standard libraries error information (i.e. when a frame is in a module belonging to those.)
"""
function install_term_stacktrace(;
    reverse_backtrace::Bool = true,
    max_n_frames::Int = 30,
    hide_frames = true,
)
    @eval begin
        function Base.showerror(args...; kwargs...)
            println("Catchy", args, kwargs)
        end

        function Base.showerror(io::IO, er, bt::Nothing; backtrace = true)
            Base.showerror(io, er, Any[]; backtrace = backtrace)
        end

        function Base.showerror(io::IO, er, bt::Vector; backtrace = true)
            print("\n")
            # @info "SHOWERROR" er bt backtrace string(io) io.io (isa(io.io, Base.TTY))
            theme = TERM_THEME[]
            isa(er, StackOverflowError) && (bt = [bt[1:25]..., bt[(end - 25):end]...])

            # if the terminal is too narrow, avoid using Term's functionality
            if default_stacktrace_width() < 70
                println(io)
                @warn "Term.jl: can't render error message, console too narrow. Using default stacktrace"
                Base.show_backtrace(io, bt)
                print(io, '\n'^3)
                Base.showerror(io, er)
                return
            end

            try
                ename = string(typeof(er))
                length(bt) > 0 && print(
                    hLine(
                        "{default bold $(theme.err_errmsg)}$ename{/default bold $(theme.err_errmsg)}";
                        style = "dim $(theme.err_errmsg)",
                    ),
                )

                # print error backtrace or panel
                if length(bt) > 0
                    rendered_bt = render_backtrace(
                        bt;
                        reverse_backtrace = $(reverse_backtrace),
                        max_n_frames = $(max_n_frames),
                        hide_frames = $(hide_frames),
                    )
                    print(rendered_bt)
                end

                # check if we should print the message panel or if that's handled by a second call to this function with vscode
                isa(io.io, Base.TTY) &&
                    Panel(
                        RenderableText(error_message(er));
                        width = default_stacktrace_width(),
                        title = "{bold $(theme.err_errmsg) default underline}$(typeof(er)){/bold $(theme.err_errmsg) default underline}",
                        padding = (2, 2, 1, 1),
                        style = "dim $(theme.err_errmsg)",
                        title_justify = :center,
                        fit = false,
                    ) |> print

            catch cought_err  # catch when something goes wrong during error handling in Term
                # @error "Term.jl: error while rendering error message: " exception =
                #     cought_err
                Base.show_backtrace(io, bt)
                print(io, '\n'^3)
                Base.showerror(io, er)
            end
        end
    end
end

end
