module Logs

using ProgressLogging: asprogress
using InteractiveUtils
using Dates: Dates
using Logging

import Term:
    Theme,
    textlen,
    escape_brackets,
    unescape_brackets,
    reshape_text,
    has_markup,
    rint,
    highlight,
    TERM_THEME,
    str_trunc,
    ltrim_str

import ..Consoles: console_width, console_height, change_scroll_region, move_to_line
import ..Renderables: AbstractRenderable, RenderableText
import ..Style: apply_style
import ..Tprint: tprintln, tprint
import ..Boxes: BOXES
import ..Progress:
    ProgressBar,
    ProgressJob,
    DescriptionColumn,
    ProgressColumn,
    render,
    start!,
    stop!,
    addjob!,
    removejob!,
    update!,
    getjob,
    SeparatorColumn,
    PercentageColumn
import ..Measures: width, height
import ..Layout: hstack, rvstack, lvstack, vertical_pad, pad, vLine

export TermLogger, install_term_logger

DEFAULT_LOGGER = global_logger()

# ---------------------------- create term logger ---------------------------- #
"""
    TermLogger

Custom logger type.
"""
struct TermLogger <: AbstractLogger
    io::IO
    theme::Theme
    pbar::ProgressBar
end
TermLogger(theme::Theme = TERM_THEME[]) = TermLogger(stderr, theme)

function TermLogger(io::IO, theme::Theme = TERM_THEME[])
    return TermLogger(
        io,
        theme,
        ProgressBar(;
            transient = true,
            columns = [
                DescriptionColumn,
                SeparatorColumn,
                ProgressColumn,
                SeparatorColumn,
                PercentageColumn,
            ],
        ),
    )
end

# set logger beavior
Logging.min_enabled_level(logger::TermLogger) = Logging.Info

Logging.shouldlog(logger::TermLogger, level, _module, group, id) = true
Logging.catch_exceptions(logger::TermLogger) = true

# --------------------------- handle logger message -------------------------- #

"""
    print_closing_line(color::String, width::Int)

Print the final line of a log message with style and date info
"""
function print_closing_line(color::String, width::Int = 48)
    tprintln(
        "  {$color bold dim}$(BOXES[:ROUNDED].bottom.left)" *
        "$(BOXES[:ROUNDED].row.mid)"^(width) *
        "{/$color bold dim}",
    )
    _date = Dates.format(Dates.now(), "e, dd u yyyy")
    _time = Dates.format(Dates.now(), "HH:MM:SS")
    pad = width - textlen(_date * _time) - 2
    return tprintln(
        " "^pad * "{dim}$_date{/dim} {bold dim underline}$_time{/bold dim underline}";
        highlight = false,
    )
end

"""
    handle_progress(logger::TermLogger, prog)

Handle progress information passed by `ProgressLogging`.

It creates/adds/removes `ProgressJob`s to the logger's
`ProgressBar` to create progress visualizations. 
"""
function handle_progress(logger::TermLogger, prog)
    pbar = logger.pbar
    pbar.running || start!(pbar)

    # if progress not started yet, ignore
    (isnothing(prog.fraction) || prog.fraction == 0) && return nothing

    # check if a job exists for this progress, or add one
    job = getjob(pbar, prog.id)
    job = if isnothing(job)
        addjob!(
            pbar;
            description = length(prog.name) > 0 ? prog.name : "running...",
            N = 100,
            transient = false,
            id = prog.id,
        )
    else
        job
    end

    # if done, remove job.
    if prog.done || prog.fraction == 1.0
        job.i = 100
        stop!(job)
    else
        update!(job; i = (Int ∘ floor)(prog.fraction * 100))
    end

    # render
    if all(map(j -> j.finished, pbar.jobs))
        map(j -> removejob!(pbar, j), pbar.jobs)
        stop!(pbar)
    else
        render(pbar)
    end
end

"""
    handle_message(logger::TermLogger, lvl, msg, _mod, group, id, file, line; kwargs...)

Handle printing of log messages, with style!.

In addition to the log message and info such as file/line and time of log, 
it prints kwargs styled by their type.
"""
function Logging.handle_message(
    logger::TermLogger,
    lvl,
    msg,
    _mod,
    group,
    id,
    file,
    line;
    kwargs...,
)
    # handle log progress
    _progress = asprogress(lvl, msg, _mod, group, id, file, line; kwargs...)
    isnothing(_progress) || return handle_progress(logger, _progress)

    # get name of function where logging message was called from
    fname = ""
    for frame in stacktrace()
        if "$(frame.file)" == file && frame.line == line
            fname = ".{underline}$(frame.func){/underline}"
        end
    end
    fname = split(fname, ".")[end]

    # prepare styles
    color = if lvl == Logging.Info
        logger.theme.info
    elseif lvl == Logging.Debug
        logger.theme.debug
    elseif lvl == Logging.Warn
        logger.theme.warn
    elseif lvl == Logging.Error
        logger.theme.error
    else
        "#90CAF9"
    end
    outline_markup = "$color dim"
    vert = "{$outline_markup}" * BOXES[:ROUNDED].mid.left * "{/$outline_markup}"

    # ---------------------------------- message --------------------------------- #
    logmsg_color = logger.theme.logmsg
    msg = string(msg)
    msg = length(msg) > 1500 ? ltrim_str(msg, 1500 - 3) * "..." : msg

    # prepare the first line: function name and log message
    fn_color = logger.theme.func
    firstline = "{$color underline bold}@$(string(lvl)){/$color underline bold} {$fn_color }($(_mod)$fname):{/$fn_color }"

    # print first line
    msg = RenderableText(
        msg;
        width = console_width() - textlen(firstline) - 1,
        style = logmsg_color,
    )
    vline = "  " * vLine(msg.measure.h; style = outline_markup)
    tprint((firstline / vline) * " " * msg; highlight = false)

    # --------------------------------- contents --------------------------------- #
    # if no kwargs we can just quit
    if length(kwargs) == 0
        print_closing_line(color)
        return nothing
    end

    """
        For each kwarg, get the type and the content, as string.
        Optionally trim these strings to ensure formatting is fine.
    """

    # Create display of type,k->v for each kwarg
    _types = map(t -> t isa Function ? Function : typeof(t), (collect(values(kwargs))))
    types_w = min(console_width() / 5, maximum(width.(string.(_types)))) |> round |> Int

    _keys = map(k -> string(k), keys(kwargs))
    keys_w = min(console_width() / 5, maximum(width.(_keys))) |> round |> Int

    _vals = map(v -> highlight(string(v)), collect(values(kwargs)))
    vals_w = min(console_width() / 5 * 3 - 7, maximum(width.(_vals)) - 7) |> round |> Int

    # function to format content, style and shape
    fmt_str(x, style::String, w::Int) = RenderableText(string(x); width = w, style = style)
    fmt_str(::Function, style::String, w::Int) =
        RenderableText("Function"; style = style, width = w)

    # get types, keys and values as RenderableText with style
    ks = fmt_str.(_keys, logger.theme.text_accent, keys_w)
    ts = fmt_str.(_types, "dim " * logger.theme.type, types_w)
    vs = fmt_str.(_vals, "", vals_w)

    # print all kwargs
    eq = "{$(logger.theme.operator)}={/$(logger.theme.operator)}"
    tprintln("  $vert"; highlight = false)
    for (t, k, v) in zip(ts, ks, vs)
        # get the height of the tallest piece of content on this line
        h = maximum(height.([k, v, t]))

        # make sure all renderables have the same height and each columns' renderable has the right width
        t = vertical_pad(pad(t; width = types_w, method = :left); height = h, method = :top)
        k = vertical_pad(pad(k; width = keys_w, method = :left); height = h, method = :top)
        v = vertical_pad(pad(v; width = vals_w, method = :right); height = h, method = :top)

        # make vertical line and =
        line = join(repeat(["  $vert"], h), "\n")
        equal = vertical_pad(eq, h, :top)

        hstack(line, t, k, equal, v; pad = 1) |> tprint
    end
    return print_closing_line(color)
end

# ---------------------------- install term logger --------------------------- #

"""
    install_term_logger(theme::Theme=theme)

Install `TermLogger` as the global logging system.

`theme::Theme` can be passed to specify the theme to use for styling objects.
"""
function install_term_logger(theme::Theme = TERM_THEME[])
    _logger = TermLogger(theme)
    return global_logger(_logger)
end

function uninstall_term_logger()
    logger = global_logger(DEFAULT_LOGGER)
    return logger
end

end
