import Base.StackTraces: StackFrame
import MyterialColors: pink, indigo_light
import Term: DEFAULT_WIDTH

function render_frame_info(frame::StackFrame; show_source = true)
    func = sprint(StackTraces.show_spec_linfo, frame)
    func = replace(
        func,
        r"(?<group>^[^(]+)" =>
            SubstitutionString("{#ffc44f}" * s"\g<0>" * "{/#ffc44f}"),
    )
    # func = highlight(reshape_text(func, 70))
    func = reshape_text(highlight(func), 70)

    # get other information about the function 
    inline = frame.inlined ? RenderableText("   inlined"; style = "bold dim white") : ""
    c = frame.from_c ? RenderableText("   from C"; style = "bold dim white") : ""

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
        func_line /= " {$pink dim}────{/$pink dim} {#9bb3e0}In module {$pink bold}$(m){/$pink bold}  {$pink dim}────{/$pink dim}{/#9bb3e0}"
    end

    if length(string(frame.file)) > 0
        file_line = RenderableText(
            "    {dim}$(file):{bold white}$(frame.line){/bold white}{/dim}";
            width = DEFAULT_WIDTH[],
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
                lvstack(
                    out,
                    Panel(
                        error_source;
                        fit = true,
                        width = 44,
                        subtitle = "error line",
                        style = "dim",
                        subtitle_style = "default bold",
                    );
                    pad = 1,
                )
            end
        end
        return out
    else
        return RenderableText("   " * func; width = DEFAULT_WIDTH[])
    end
end

function render_backtrace_frame(
    num::RenderableText,
    info::AbstractRenderable;
    as_panel = true,
    kwargs...,
)
    content = hstack(num, info, pad = 2)
    p = if as_panel
        Panel(content; padding = (2, 2, 1, 1), style = "#9bb3e0", fit = true, kwargs...)
    else
        "   " * content
    end

    return p / " "
end

function render_backtrace(bt::Vector; reverse_backtrace = true, max_n_frames = 30)
    length(bt) == 0 && return RenderableText("")

    if reverse_backtrace
        bt = reverse(bt)
    end

    content::Vector = []
    added_skipped_message = false
    N = length(bt)
    for (num, frame) in enumerate(bt)
        numren = RenderableText("($(num))"; style = "#52c4ff bold dim")
        info = render_frame_info(frame; show_source = num in (1, length(bt)))

        if num == 1
            push!(
                content,
                render_backtrace_frame(
                    numren,
                    info;
                    subtitle = reverse_backtrace ? "TOP LEVEL" : "ERROR LINE",
                    subtitle_style = reverse_backtrace ? "white" : "bold white",
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
                    subtitle_style = reverse_backtrace ? "bold white" : "white",
                    subtitle_justify = :right,
                ),
            )

        else
            if num > max_n_frames && num < length(bt) - 5
                if added_skipped_message == false
                    skipped_line = hLine(
                        content[1].measure.w,
                        "{blue dim bold}$(N - max_n_frames - 2){/blue dim bold}{blue dim} frames skipped{/blue dim}";
                        style = "blue dim",
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
        lvstack(content...);
        padding = (2, 2, 0, 1),
        subtitle = "Error Stack",
        style = "#ff8a4f dim",
        subtitle_style = "bold #ff8a4f default",
        title = "Error Stack",
        title_style = "bold #ff8a4f default",
        fit = true,
    )
end
