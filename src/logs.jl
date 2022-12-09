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
import ..Layout: hstack, rvstack, lvstack, vertical_pad, pad

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
    v = textlen(v) > 33 ? v[1:30] * "..." : v
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

    # prepare the first line of information
    fn_color = logger.theme.func
    firstline = "{$color underline bold}@$(string(lvl)){/$color underline bold} {$fn_color }($(_mod)$fname):{/$fn_color }"
    
    # print first line
    msg_lines = split(msg, "\n")
    length(msg_lines) > 0 &&
        (firstline *= "  " * RenderableText(reshape_text(msg_lines[1], console_width() - textlen(firstline)); style=logmsg_color))
    tprintln(firstline; highlight = false)

    # for multi-lines message, print each line separately.
    _vert = "  $vert   "
    vert_width = textlen(_vert)
    for n in 2:length(msg_lines)
        # make sure the text fits in the given space
        txt = RenderableText(reshape_text(msg_lines[n], console_width()-vert_width-1); style=logmsg_color)
        v = join(repeat([_vert], height(txt)), "\n")
        tprint(v * txt; highlight=false)
    end

    # --------------------------------- contents --------------------------------- #
    # if no kwargs we can just quit
    if length(kwargs) == 0 || length(msg_lines) == 0
        print_closing_line(color)
        return nothing
    end

    """
        For each kwarg, get the type and the content, as string.
        Optionally trim these strings to ensure formatting is fine.
    """

    # function to reshape all content appropriately
    w = min(120, (Int ∘ round)((console_width() - 6) / 4))   # six to allow space for vert and =
    fmt_str(x, style; f = 1) = RenderableText(reshape_text(string(x), f * w); style = style)
    fmt_str(::Function, style; f = 1) =
        RenderableText(reshape_text("Function", f * w); style = style)

    # get types, keys and values as RenderableText with style
    ks = map(k -> fmt_str(k, logger.theme.text_accent), keys(kwargs))

    _types = map(t -> t isa Function ? Function : typeof(t), (collect(values(kwargs))))
    _types = map(t -> fmt_str("$t::", "dim " * logger.theme.type), _types)

    vals = map(v -> style_log_msg_kw_value(logger, v), collect(values(kwargs)))
    vals_style = [x[2] for x in vals]
    vv = first.(vals)
    vals = map(i -> fmt_str(vv[i], vals_style[i]; f = 2), 1:length(vv))

    # get the ma width of each piece of content
    type_w = maximum(width.(_types))
    keys_w = maximum(width.(ks))
    vals_w = maximum(width.(vals))

    # print all kwargs
    eq = "{$(logger.theme.operator)}={/$(logger.theme.operator)}"
    tprintln("  $vert"; highlight = false)
    for (t, k, v) in zip(_types, ks, vals, _types)
        # get the height of the tallest piece of content on this line
        h = maximum(height.([k, v, t]))

        # make sure all renderables have the same height and each columns' renderable has the right width
        t = vertical_pad(pad(t; width = type_w, method = :left); height = h, method = :top)
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
