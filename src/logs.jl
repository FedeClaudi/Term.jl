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
import ..Renderables: AbstractRenderable
import ..Style: apply_style
import ..Tprint: tprintln
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

    # style message
    logmsg_color = logger.theme.logmsg
    msg = string(msg)
    msg = length(msg) > 1500 ? ltrim_str(msg, 1500 - 3) * "..." : msg

    # get the first line of information
    fn_color = logger.theme.func
    content = "{$color underline bold}@$(string(lvl)){/$color underline bold} {$fn_color }($(_mod)$fname):{/$fn_color }"

    # for multi-lines message, print each line separately.
    msg_lines::Vector{AbstractString} = split(msg, "\n")
    for n in 2:length(msg_lines)
        msg_lines[n] =
            "  $vert   " * " "^(textlen(content) - 4) * "{$logmsg_color}" * msg_lines[n]
    end

    length(msg_lines) > 0 && (content *= "  " * msg_lines[1])

    tprintln(content; highlight = false)
    tprintln.(msg_lines[2:end]; highlight = false)

    # if no kwargs we can just quit
    if length(kwargs) == 0 || length(msg_lines) == 0
        print_closing_line(color)
        return nothing
    end

    # get padding width
    _types = string.(typeof.(collect(values(kwargs))))
    _types = map(t -> str_trunc(t, 24), _types)
    for (i, _type) in enumerate(values(kwargs))
        typeof(_type) <: Function && (_types[i] = string(Function))
    end

    wpad = 24 - maximum(textlen.(_types)) + 2
    ks = str_trunc.(string.(keys(kwargs)), 28)
    namepad = maximum(textlen.(ks))

    # print all kwargs
    tprintln("  $vert"; highlight = false)
    for (k, v, _type) in zip(ks, values(kwargs), _types)
        # get line stub
        pad = max(wpad - textlen(_type) - 1, 1)
        line =
            "  $vert" *
            " "^pad *
            " {$(logger.theme.type) dim}($(_type)){/$(logger.theme.type) dim}" *
            " {bold $(logger.theme.text)}$k{/bold $(logger.theme.text)}"

        epad = namepad - textlen(string(k))
        line *=
            " "^epad * " {bold $(logger.theme.operator)}={/bold $(logger.theme.operator)} "
        lpad = textlen(line) - 4

        # get value style
        if v isa Number
            _style = logger.theme.number
        elseif v isa Symbol
            _style = logger.theme.symbol
        elseif v isa AbstractString
            _style = logger.theme.string
        elseif v isa AbstractVector
            _style = logger.theme.number
            _size = length(v)
            v = escape_brackets(string(v))
            v = textlen(v) > 33 ? v[1:30] * "..." : v
            v *= "\n {$(logger.theme.text)}$(_size) {/$(logger.theme.text)}{dim}items{/dim}"
        elseif v isa AbstractArray || v isa AbstractMatrix
            _style = logger.theme.number
            _size = size(v)
            v = str_trunc("$(typeof(v)) {dim}<: $(supertypes(typeof(v))[end-1]){/dim}", 60)
            v *=
                "\n {dim}shape: {default $(logger.theme.text)}" *
                join(string.(_size), " × ") *
                "{/default $(logger.theme.text)}{/dim}"

        elseif v isa Function
            _style = logger.theme.func
        elseif v isa AbstractRenderable
            _style = "default"
            v = "$(typeof(v)) \e[2m(size: $(v.measure))\e[0m"
        else
            _style = nothing
        end

        # print value lines
        v = reshape_text(str_trunc(string(v), 177), 44)
        vlines = split(v, "\n")

        vlines = if !isnothing(_style)
            map(ln -> "{" * _style * "}" * ln * "{/" * _style * "}", vlines)
        else
            highlight.(vlines)
        end

        tprintln(line * vlines[1]; highlight = false)
        if length(vlines) ≥ 1
            for ln in vlines[2:end]
                tprintln("  $vert " * " "^lpad * ln; highlight = false)
            end
        end
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
    _lg = global_logger(DEFAULT_LOGGER)
    logger = global_logger(DEFAULT_LOGGER)
    return logger
end

end
