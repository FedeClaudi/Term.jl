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
    ltrim_str,
    default_width,
    NOCOLOR,
    cleantext

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
function print_closing_line(io::IO, color::String, width::Int = 48)
    tprintln(
        io,
        "  {$color bold dim}$(BOXES[:ROUNDED].bottom.left)" *
        "$(BOXES[:ROUNDED].row.mid)"^(width) *
        "{/$color bold dim}",
    )
    _date = Dates.format(Dates.now(), "e, dd u yyyy")
    _time = Dates.format(Dates.now(), "HH:MM:SS")
    pad = width - textlen(_date * _time) - 2
    return tprintln(
        io,
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

style_log_msg_kw_value(logger, v::Number) = (v, logger.theme.number)
style_log_msg_kw_value(logger, v::Symbol) = (v, logger.theme.symbol)
style_log_msg_kw_value(logger, v::AbstractString) = (v, logger.theme.string)
style_log_msg_kw_value(logger, v::Function) = (v, logger.theme.func)
style_log_msg_kw_value(logger, v::AbstractRenderable) =
    ("$(typeof(v))  \e[2m$(v.measure)\e[0m", "default")
style_log_msg_kw_value(logger, v) = (v, nothing)

function style_log_msg_kw_value(logger, v::AbstractVector)
    _style = logger.theme.number
    _size = length(v)
    v = escape_brackets(string(v))
    v = textlen(v) > 60 ? v[1:57] * "..." : v
    v *= "\n {$(logger.theme.text)}$(_size) {/$(logger.theme.text)}{dim}items{/dim}"
    return (v, _style)
end
function style_log_msg_kw_value(logger, v::Union{AbstractArray,AbstractMatrix})
    _style = logger.theme.number
    _size = size(v)
    v = str_trunc("$(typeof(v)) {dim}<: $(supertypes(typeof(v))[end-1]){/dim}", 60)
    v *=
        "\n {dim}shape: {default $(logger.theme.text)}" *
        join(string.(_size), " × ") *
        "{/default $(logger.theme.text)}{/dim}"
    return (v, _style)
end

"""
Create string display for a log message value.
"""
function log_value_display end

function log_value_display(x::AbstractArray)
    a = highlight(str_trunc(string(x), 1000); ignore_ansi = true)

    s = foldl((a, b) -> a * " × " * b, string.(size(x)))
    b = highlight("{bold dim}Size:  $(s){/bold dim}"; ignore_ansi = true)
    return a * "\n" * b
end

log_value_display(x::AbstractDict) =
    highlight(str_trunc(string(x), 1000); ignore_ansi = true)
log_value_display(x) = highlight(str_trunc(string(x), 1000);)

function print_log_message(io, logger, lvl, msg, _mod, file, line, kwargs)

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
    tprint(io, (firstline / vline) * " " * msg; highlight = false)

    # --------------------------------- contents --------------------------------- #
    # if no kwargs we can just quit
    if length(kwargs) == 0
        print_closing_line(io, color)
        return nothing
    end

    """
        For each kwarg, get the type and the content, as string.
        Optionally trim these strings to ensure formatting is fine.
    """

    # Create display of type,k->v for each kwarg
    _types = map(t -> t isa Function ? Function : typeof(t), (collect(values(kwargs))))
    types_w = min(console_width() / 5, maximum(width.(string.(_types)))) |> round |> Int
    types_w = max(12, types_w)

    _keys = map(k -> highlight(string(k), theme = logger.theme), keys(kwargs))
    keys_w = min(console_width() / 5, maximum(width.(_keys))) |> round |> Int
    keys_ = max(12, keys_w)

    _vals = map(v -> log_value_display(v), collect(values(kwargs)))
    vals_w = min(console_width() / 5 * 3 - 7, maximum(width.(_vals)) - 7) |> round |> Int
    vals_w = max(12, vals_w)

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
    tprint(io, "  $vert"; highlight = false)
    print(io, "\n")
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

        ll = hstack(line, t, k, equal, v; pad = 1)
        tprint(io, ll)
    end
    print_closing_line(io, color)
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

    # generate log 
    logged = sprint(print_log_message, logger, lvl, msg, _mod, file, line, kwargs)

    # restore stdout
    NOCOLOR[] && (logged = cleantext(logged))
    print(logged)
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
