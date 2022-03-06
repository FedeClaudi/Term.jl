
module logging
    import Dates
    using Logging
    using InteractiveUtils

    import Term: Theme, theme, textlen, square_to_round_brackets, escape_brackets, reshape_text
    import ..markup: has_markup
    import ..box: ROUNDED
    import ..style: apply_style

    export TermLogger, install_term_logger

    tprint = (println ∘ apply_style)

    # ---------------------------- create term logger ---------------------------- #
    # create logger
    struct TermLogger <: Logging.AbstractLogger
        io::IO
        theme::Theme
    end
    TermLogger(theme::Theme) = TermLogger(stderr, theme)


    # set logger beavior
    Logging.min_enabled_level(logger::TermLogger) = Logging.Info
    function Logging.shouldlog(logger::TermLogger, level, _module, group, id)
        return true
    end
    Logging.catch_exceptions(logger::TermLogger) = true

    # --------------------------- handle logger message -------------------------- #

    """
        print_closing_line(color::String, width::Int)

    Prints the final line of a log message with style and date info
    """
    function print_closing_line(color::String, width::Int)
        tprint("  [$color bold dim]$(ROUNDED.bottom.left)" * "$(ROUNDED.row.mid)"^(width) * "[/$color bold dim]")
        _date = Dates.format(Dates.now(), "e, dd u yyyy")  
        _time = Dates.format(Dates.now(), "HH:MM:SS")  
        pad = width - textlen(_date * _time) - 2
        tprint(" "^pad * "[dim]$_date[/dim] [bold dim underline]$_time[/bold dim underline]")
    end



    """
    Logging.handle_message(logger::TermLogger,

    Handles printing of log messages, with style!.
    In addition to the log message and info such as file/line and time of log, 
    it prints kwargs styled by their type.
    """
    function Logging.handle_message(logger::TermLogger,
        lvl, msg, _mod, group, id, file, line;
        kwargs...)
        
        # get name of function where logging message was called from
        fname = ""
        for frame in stacktrace()
            if "$(frame.file)"==file && frame.line == line
                fname = "[$(logger.theme.func) underline]$(frame.func)[/$(logger.theme.func) underline]"
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
        hor = "[$outline_markup]▶[/$outline_markup]"
        vert = "[$outline_markup]" * ROUNDED.mid.left * "[/$outline_markup]"

        # style message
        msg = has_markup(msg) ? msg : "[#8abeff]$msg[/#8abeff]"
        msg = reshape_text(msg, 64)


        # print the first line of information
        content = """
[$color underline bold]@$(string(lvl))[/$color underline bold] [#edb46f ]($(_mod).$fname):[/#edb46f ] $msg
  $vert   [dim]$(file):$(line) [/dim][bold dim](line: $(line))[/bold dim]"""
        tprint(content)
        lw = min((Int ∘ round)(textlen(content) * .75), 48)

        # if no kwargs we can just quit
        if length(kwargs) == 0
            print_closing_line(color, lw)
            return
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
        tprint("  $vert")
        for ((k,v), _type) in zip(kwargs, _types)
            # get line stub
            pad = wpad - textlen(_type)
            line = "  $vert [$(theme.type) dim]($(_type))[/$(theme.type) dim]" * " "^pad * hor * "  [bold #ff9959]$k[/bold #ff9959]"
            
            epad = namepad - textlen(string(k))
            line *= " "^epad * " [bold red]=[/bold red] "
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
                _size = size(v)
                v = square_to_round_brackets(string(v)) 
                v = textlen(v) > 33 ? v[1:30] * " ...)" : v
                v *= "\n [dim]size: $(_size)[/dim]"
            elseif v isa AbstractArray || v isa AbstractMatrix
                _style = logger.theme.number
                v = "$(typeof(v)) [dim]<: $(supertypes(typeof(v))[end-1])[/dim]" * "\n [dim]size: $(size(v))[/dim]"
            elseif v isa Function
                _style = logger.theme.func
            else
                _style = nothing
            end

            # print value lines
            vlines = split(string(v), "\n")

            if !isnothing(_style)
                vlines = ["[$_style]$ln[/$_style]" for ln in vlines]
            end

            if length(vlines) == 1
                tprint(line * vlines[1])
            else
                tprint(line * vlines[1])
                for ln in vlines[2:end]
                    tprint("  $vert " * " "^lpad * ln)
                end
            end
        end
        print_closing_line(color, lw)
    end

    # ---------------------------- install term logger --------------------------- #
    function install_term_logger(theme::Theme=theme)
        _logger = TermLogger(theme)
        global_logger(_logger)
    end
end