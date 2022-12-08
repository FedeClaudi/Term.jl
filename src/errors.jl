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
    TERM_THEME

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
    println(obj)
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
    return er.msg / "The invalid value is: $(er.val)."
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

    # if contains(candidate, "##kw")
    #     name = split(candidate, "\")(")[1]
    #     name = replace(name, "(::Core.var\"#"=>"", "##kw"=>"")

    #     @info "candidate" fun candidate name

    # end

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

function error_message(er::MethodError; kwargs...)
    f = er.f
    ft = typeof(f)
    name = ft.name.mt.name
    # kwargs = ()
    # if endswith(string(ft.name.name), "##kw")
    #     f = er.args[2]
    #     ft = typeof(f)
    #     name = ft.name.mt.name
    #     # arg_types_param = arg_types_param[3:end]
    #     kwargs = pairs(er.args[1])
    #     # er = MethodError(f, er.args[3:end::Int])
    # end

    # get main error message
    @info "args" er.args er.args[1]
    args_types = map(
        a -> a isa NamedTupleds ? "Tuple" : (a |> typeof |> string), er.args
    )
    _args =
        join(
            map(
                a ->
                    "{dim bold}($(a[1])){/dim bold}   $(highlight("::"*a[2]))",
                enumerate(args_types),
            ), "\n"
        ) |> apply_style
    main_line =
        "No method matching {bold $(TERM_THEME[].emphasis)}`$name`{/bold $(TERM_THEME[].emphasis)} with arguments types:" /
        _args

    # get recomended candidates
    _candidates = split(sprint(show_method_candidates, er), "\n")[3:(end - 1)]

    if length(_candidates) > 0
        _candidates = map(c -> split(c, " at ")[1], _candidates)
        candidates = map(c -> method_error_candidate(name, c), _candidates)
        main_line /=
            lvstack("", "Alternative candidates:", candidates...) |> string |> apply_style
    else
        main_line = main_line / " " / "{dim}No alternative candidates found"
    end

    return string(main_line)
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
            "no message for error of type $(typeof(er)), sorry."
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
function install_term_stacktrace(; reverse_backtrace::Bool = true, max_n_frames::Int = 30, hide_base=true)
    @eval begin
        function Base.showerror(io::IO, er, bt; backtrace = true)
            
            theme = TERM_THEME[]
            (length(bt) == 0 && !isa(er, StackOverflowError)) && return nothing
            isa(er, StackOverflowError) && (bt = [bt[1:25]..., bt[(end - 25):end]...])

            if default_stacktrace_width() < 70
                println(io)
                @warn "Term.jl: can't render error message, console too narrow. Using default stacktrace"
                Base.show_backtrace(io, bt)
                print(io, '\n'^3)
                Base.showerror(io, er)
                return
            end

            try
                println("\n")
                ename = string(typeof(er))
                print(
                    hLine(
                        "{default bold $(theme.err_errmsg)}$ename{/default bold $(theme.err_errmsg)}";
                        style = "dim $(theme.err_errmsg)",
                    ),
                )

                # print error stacktrace
                if length(bt) > 0
                    rendered_bt = render_backtrace(
                        bt;
                        reverse_backtrace = $(reverse_backtrace),
                        max_n_frames = $(max_n_frames),
                        hide_base = $(hide_base)
                    )
                    print(rendered_bt)
                end

                # print error message and description
                Panel(
                    RenderableText(
                        error_message(er),
                        # width = default_stacktrace_width() - 4,
                    );
                    width = default_stacktrace_width(),
                    title = "{bold $(theme.err_errmsg) default underline}$(typeof(er)){/bold $(theme.err_errmsg) default underline}",
                    padding = (2, 2, 1, 1),
                    style = "dim $(theme.err_errmsg)",
                    title_justify = :center,
                    fit = false,
                ) |> print

            catch cought_err  # catch when something goes wrong during error handling in Term
                @error "Term.jl: error while rendering error message: " exception =
                    cought_err
                Base.show_backtrace(io, bt)
                print(io, '\n'^3)
                Base.showerror(io, er)
            end
        end
    end
end

end
