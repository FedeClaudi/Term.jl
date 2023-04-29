module Errors

import Base: show_method_candidates, ExceptionStack, InterpreterIP

import Term:
    highlight,
    highlight_syntax,
    str_trunc,
    reshape_text,
    load_code_and_highlight,
    default_stacktrace_width,
    escape_brackets,
    unescape_brackets,
    remove_markup,
    TERM_THEME,
    plural,
    Theme,
    do_by_line,
    STACKTRACE_HIDDEN_MODULES,
    STACKTRACE_HIDE_FRAMES,
    reshape_code_string,
    TERM_SHOW_LINK_IN_STACKTRACE,
    NOCOLOR,
    cleantext

# import ..Links: Link
import ..Style: apply_style
import ..Layout:
    hLine,
    rvstack,
    cvstack,
    rvstack,
    vstack,
    vLine,
    Spacer,
    hstack,
    lvstack,
    pad,
    vertical_pad
import ..Renderables: RenderableText, AbstractRenderable
import ..Panels: Panel
import ..Measures: height

export install_term_stacktrace

"""
Stores information useful for creating the layout
of a stack trace visualization.
"""
struct StacktraceContext
    out_w::Int              # max width of the stacktrace
    frame_panel_w::Int      # width of inner elements like frame panels
    module_line_w::Int      # width of hline to print module name
    func_name_w::Int        # width of frame's function name and file
    code_w::Int             # width of code panels
    theme::Theme
end

function StacktraceContext(w = default_stacktrace_width())
    frame_panel_w = w - 4 - 12 - 3 # panel walls and padding
    module_line_w = w - 4 - 4
    func_name_w = frame_panel_w - 4 - 8 # including (n) before fname
    code_w = func_name_w - 8
    return StacktraceContext(
        w,
        frame_panel_w,
        module_line_w,
        func_name_w,
        code_w,
        TERM_THEME[],
    )
end

include("_errors.jl")

# ---------------------------------------------------------------------------- #
#                              INSTALL STACKTRACE                              #
# ---------------------------------------------------------------------------- #

function print_term_error(io::IO, er, bt, reverse_backtrace, max_n_frames, hide_frames)
    try
        # create a StacktraceContext
        ctx = StacktraceContext()

        # print an hLine with the error name
        ename = string(typeof(er))
        length(bt) > 0 && print(
            io,
            hLine(
                ctx.out_w,
                "{default bold $(ctx.theme.err_errmsg)}$ename{/default bold $(ctx.theme.err_errmsg)}";
                style = "dim $(ctx.theme.err_errmsg)",
            ),
        )

        # print error backtrace or panel
        if length(bt) > 0
            rendered_bt = render_backtrace(
                ctx,
                bt;
                reverse_backtrace = reverse_backtrace,
                max_n_frames = max_n_frames,
                hide_frames = hide_frames,
            )
            print(io, rendered_bt)
        end

        # print message panel if VSCode is not handling that through a second call to this fn

        msg = highlight(sprint(Base.showerror, er)) |> apply_style
        err_panel = Panel(
            RenderableText(
                reshape_code_string(msg, ctx.module_line_w);
                width = ctx.module_line_w,
            );
            width = ctx.out_w,
            title = "{bold $(ctx.theme.err_errmsg) default underline}$(typeof(er)){/bold $(ctx.theme.err_errmsg) default underline}",
            padding = (2, 2, 1, 1),
            style = "dim $(ctx.theme.err_errmsg)",
            title_justify = :center,
            fit = false,
        )
        print(io, err_panel)

    catch cought_err  # catch when something goes wrong during error handling in Term
        @error "Term.jl: error while rendering error message: " cought_err

        for (i, (exc, _bt)) in enumerate(current_exceptions())
            i == 1 && println(io, "Error during term's stacktrace generation:")
            Base.show_backtrace(io, _bt)
            print('\n'^3)
            Base.showerror(io, exc)
        end

        print('\n'^5)
        println(io, "Original error:")
        Base.show_backtrace(io, bt)
        print('\n'^3)
        Base.showerror(io, er)
    end
end

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
        function Base.showerror(io::IO, er, bt; backtrace = true)
            print(io, "\n")
            # @info "Showing" er bt

            # shorten very long backtraces
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

            # print
            err = sprint(
                print_term_error,
                er,
                bt,
                $(reverse_backtrace),
                $(max_n_frames),
                $(hide_frames),
            )
            NOCOLOR[] && (err = cleantext(err))
            print(io, err)
        end
    end
end

end
