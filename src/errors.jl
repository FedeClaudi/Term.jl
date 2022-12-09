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

include("_error_messages.jl")
include("_errors.jl")


"""
Stores information useful for creating the layout
of a stack trace visualization.
"""
struct StacktraceContext
    out_w::Int        # max width of the stacktrace
    inner_w::Int      # width of inner elements like frame panels
    fname_w::Int      # width of frame's function name and file
    code_w::Int       # width of code panels
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
