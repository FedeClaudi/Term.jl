import Base.StackTraces: StackFrame
import MyterialColors: pink, indigo_light

function render_frame_info(pointer::Ptr{Nothing}; show_source = true)
    frame = StackTraces.lookup(pointer)[1]
    return render_frame_info(frame; show_source = show_source)
    # return RenderableText("   " * string(frame); width = default_stacktrace_width() - 12)
end

function render_frame_info(frame::StackFrame; show_source = true)
    theme = TERM_THEME[]
    func = sprint(StackTraces.show_spec_linfo, frame)
    func = replace(
        func,
        r"(?<group>^[^(]+)" =>
            SubstitutionString("{$(theme.func)}" * s"\g<0>" * "{/$(theme.func)}"),
    )
    func =
        reshape_text(highlight(func), default_stacktrace_width()) |> remove_markup |> lstrip

    # get other information about the function 
    inline =
        frame.inlined ? RenderableText("   inlined"; style = "bold dim $(theme.text)") : ""
    c = frame.from_c ? RenderableText("   from C"; style = "bold dim $(theme.text)") : ""

    # get name of module
    m = Base.parentmodule(frame)
    if m !== nothing
        while parentmodule(m) !== m
            pm = parentmodule(m)
            pm == Main && break
            m = pm
        end
    end
    m = !isnothing(m) ? string(m) : nothing

    # get other info
    file = Base.fixup_stdlib_path(string(frame.file))

    # create text
    func_line = hstack(func, inline, c; pad = 1)

    if !isnothing(m)
        accent = theme.err_accent
        func_line /= " {$accent dim}────{/$accent dim} {#9bb3e0}In module {$accent bold}$(m){/$accent bold}  {$accent dim}────{/$accent dim}{/#9bb3e0}"
    end

    if length(string(frame.file)) > 0
        file_line = RenderableText(
            "{dim}$(file):{bold $(theme.text_accent)}$(frame.line){/bold $(theme.text_accent)}{/dim}";
            width = default_stacktrace_width() - 30,
        )

        out = func_line / file_line
        if show_source
            error_source = nothing
            try
                error_source = load_code_and_highlight(string(frame.file), frame.line)
            catch
                error_source = nothing
            end

            out = if isnothing(error_source) || length(error_source) == 0
                out
            else
                code_error_panel =
                    "   " * Panel(
                        error_source;
                        fit = false,
                        style = "$(theme.text_accent) dim",
                        width = min(60, default_stacktrace_width() - 30),
                        subtitle_justify = :center,
                        subtitle = "error line",
                        subtitle_style = "default $(theme.text_accent) #fa6673",
                    )

                lvstack(out, code_error_panel; pad = 0)
            end
        end
        return out
    else
        return RenderableText("   " * func; width = default_stacktrace_width() - 4)
    end
end

function render_backtrace_frame(
    num::RenderableText,
    info::AbstractRenderable;
    as_panel = true,
    kwargs...,
)
    content = hstack(num, info, pad = 1)
    return if as_panel
        Panel(
            content;
            padding = (2, 2, 1, 1),
            style = TERM_THEME[].err_btframe_panel,
            fit = false,
            width = default_stacktrace_width() - 12,
            kwargs...,
        )
    else
        "   " * RenderableText(string(content), width = default_stacktrace_width() - 18)
    end
end

function render_backtrace(bt::Vector; reverse_backtrace = true, max_n_frames = 30)
    theme = TERM_THEME[]
    length(bt) == 0 && return RenderableText("")

    if reverse_backtrace
        bt = reverse(bt)
    end

    content = AbstractRenderable[]
    added_skipped_message = false
    N = length(bt)
    for (num, frame) in enumerate(bt)
        numren = RenderableText("($(num))"; style = "$(theme.emphasis) bold dim")
        info = render_frame_info(frame; show_source = num in (1, length(bt)))

        if num == 1
            push!(
                content,
                render_backtrace_frame(
                    numren,
                    info;
                    subtitle = reverse_backtrace ? "TOP LEVEL" : "ERROR LINE",
                    subtitle_style = reverse_backtrace ? "$(theme.text_accent)" :
                                     "bold $(theme.text_accent)",
                    subtitle_justify = :right,
                ),
            )

        elseif num == length(bt)
            push!(
                content,
                render_backtrace_frame(
                    numren,
                    info;
                    subtitle = reverse_backtrace ? "ERROR LINE" : "TOP LEVEL",
                    subtitle_style = reverse_backtrace ? "bold $(theme.text_accent)" :
                                     "$(theme.text_accent)",
                    subtitle_justify = :right,
                ),
            )

        else
            if num > max_n_frames && num < length(bt) - 5
                if added_skipped_message == false
                    skipped_line = hLine(
                        content[1].measure.w,
                        "{bold dim}$(N - max_n_frames - 2){/bold dim}{$(theme.err_btframe_panel) dim} frames skipped{/$(theme.err_btframe_panel) dim}";
                        style = "$(theme.err_btframe_panel) dim",
                    )
                    push!(content, skipped_line)
                    added_skipped_message = true
                end
            else
                push!(content, render_backtrace_frame(numren, info; as_panel = false))
            end
        end
    end

    return Panel(
        lvstack(content..., pad = 1);
        padding = (2, 2, 2, 1),
        subtitle = "Error Stack",
        style = "$(theme.er_bt) dim",
        subtitle_style = "bold $(theme.er_bt) default",
        title = "Error Stack",
        title_style = "bold $(theme.er_bt) default",
        fit = false,
        justifty = :center,
        width = default_stacktrace_width(),
    )
end
