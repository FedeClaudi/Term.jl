
module logging
using Dates: Dates
using Logging
using InteractiveUtils
using ProgressLogging: asprogress

import Term: Theme,
            textlen,
            escape_brackets,
            unescape_brackets,
            reshape_text,
            has_markup,
            int,
            highlight,
            term_theme


import ..box: ROUNDED
import ..style: apply_style
import ..renderables: AbstractRenderable
import ..Tprint: tprintln
import ..progress: ProgressBar,
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

import ..console: console_width, console_height, change_scroll_region, move_to_line

export TermLogger, install_term_logger



DEFAULT_LOGGER = global_logger()

# ---------------------------- create term logger ---------------------------- #
"""
    TermLogger

Custom logger type.
"""
struct TermLogger <: Logging.AbstractLogger
    io::IO
    theme::Theme
    pbar::ProgressBar

end
TermLogger(theme::Theme) = TermLogger(stderr, theme)

TermLogger(io::IO, theme::Theme) = TermLogger(
    io,     
    theme,
    ProgressBar(; 
        transient=true, 
        columns=[DescriptionColumn,
        SeparatorColumn,
        ProgressColumn,
        SeparatorColumn,
        PercentageColumn
        ])
)


# set logger beavior
Logging.min_enabled_level(logger::TermLogger) = Logging.Info

function Logging.shouldlog(logger::TermLogger, level, _module, group, id)
    return true
end
Logging.catch_exceptions(logger::TermLogger) = true

# --------------------------- handle logger message -------------------------- #

"""
    print_closing_line(color::String, width::Int)

Print the final line of a log message with style and date info
"""
function print_closing_line(color::String, width::Int = 48)
    tprintln(
        "  {$color bold dim}$(ROUNDED.bottom.left)" *
        "$(ROUNDED.row.mid)"^(width) *
        "{/$color bold dim}",
    )
    _date = Dates.format(Dates.now(), "e, dd u yyyy")
    _time = Dates.format(Dates.now(), "HH:MM:SS")
    pad = width - textlen(_date * _time) - 2
    return tprintln(
        " "^pad * "{dim}$_date{/dim} {bold dim underline}$_time{/bold dim underline}"; highlight=false
    )
end

"""
    handle_progress(logger::TermLogger, prog)

Handle progress information passed by `ProgressLogging`

It creates/adds/removes `ProgressJob`s to the logger's
`ProgressBar` to create progress visualizations. 
"""
function handle_progress(logger::TermLogger, prog)
    pbar = logger.pbar
    pbar.running || start!(pbar)
    

    # if progress not started yet, ignore
    if isnothing(prog.fraction) || prog.fraction == 0
        return
    end

    # check if a job exists for this progress, or add one
    job = getjob(pbar, prog.id)
    job = isnothing(job) ? addjob!(
                pbar; 
                description=length(prog.name) > 0 ? prog.name : "running...", 
                N = 100,
                transient=false,
                id = prog.id
            ) : job

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
    Logging.handle_message(logger::TermLogger,

Handle printing of log messages, with style!.

In addition to the log message and info such as file/line and time of log, 
it prints kwargs styled by their type.
"""
function Logging.handle_message(
    logger::TermLogger, lvl, msg, _mod, group, id, file, line; kwargs...
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
    if lvl == Logging.Info
        color = logger.theme.info
    elseif lvl == Logging.Debug
        color = logger.theme.debug
    elseif lvl == Logging.Warn
        color = logger.theme.warn
    elseif lvl == Logging.Error
        color = logger.theme.error
    else
        color = "#90CAF9"
    end

    outline_markup = "$color dim"
    vert = "{$outline_markup}" * ROUNDED.mid.left * "{/$outline_markup}"

    # style message
    if msg isa AbstractString
        msg = has_markup(msg) ? msg : "{#8abeff}$msg{/#8abeff}"
        msg = reshape_text(msg, 64)
    else
        msg = string(msg)
    end

    # get the first line of information
    content = "{$color underline bold}@$(string(lvl)){/$color underline bold} {#edb46f }($(_mod)$fname):{/#edb46f }"

    # for multi-lines message, print each line separately.
    msg_lines::Vector{AbstractString} = split(msg, "\n")
    for n in 2:length(msg_lines)
        msg_lines[n] = "  $vert   " * " "^textlen(content) * "{#8abeff}" * msg_lines[n]
    end
    if length(msg_lines) > 0
        content *= "  " * msg_lines[1]
    end
    tprintln(content; highlight=false)
    tprintln.(msg_lines[2:end]; highlight=false)

    # if no kwargs we can just quit
    if length(kwargs) == 0 || length(msg_lines) == 0
        print_closing_line(color)
        return nothing
    end

    # get padding width
    _types = string.(typeof.([v for v in values(kwargs)]))
    for (i, _type) in enumerate(values(kwargs))
        if typeof(_type) <: Function
            _types[i] = string(Function)
        end
    end

    wpad = max(textlen.(_types)...) + 2
    namepad = max(textlen.(string.([v for v in keys(kwargs)]))...)

    # print all kwargs
    tprintln("  $vert"; highlight=false)
    for ((k, v), _type) in zip(kwargs, _types)
        # get line stub
        pad = wpad - textlen(_type) - 1
        line =
            "  $vert" * " "^pad * " {$(logger.theme.type) dim}($(_type)){/$(logger.theme.type) dim}" *
            " {bold #e0e0e0}$k{/bold #e0e0e0}"

        epad = namepad - textlen(string(k))
        line *= " "^epad * " {bold red}={/bold red} "
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
            v *= "\n {dim}{bold}$(_size) items {/bold}{/dim}"
        elseif v isa AbstractArray || v isa AbstractMatrix
            _style = logger.theme.number
            _size = size(v)
            v =
                "$(typeof(v)) {dim}<: $(supertypes(typeof(v))[end-1]){/dim}"
            v *= "\n {dim}shape: " * join(string.(_size), " × ") * "{/dim}"

        elseif v isa Function
            _style = logger.theme.func
        elseif v isa AbstractRenderable
            _style = "default"
            v = "$(typeof(v)) \e[2m(size: $(v.measure))\e[0m"
        else
            _style = nothing
        end

        # print value lines
        vlines = split(string(v), "\n")

        if !isnothing(_style)
            vlines = map(
                ln -> "{"*_style*"}"*ln*"{/"*_style*"}", vlines
            )
        else
            vlines = highlight.(vlines)
        end

        tprintln(line * vlines[1]; highlight=false)
        if length(vlines) >= 1
            for ln in vlines[2:end]
                tprintln("  $vert " * " "^lpad * ln; highlight=false)
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
function install_term_logger(theme::Theme = term_theme[])
    _logger = TermLogger(theme)
    return global_logger(_logger)
end


function uninstall_term_logger()
    _lg = global_logger(DEFAULT_LOGGER)
    logger = global_logger(DEFAULT_LOGGER)
    return logger
end
end