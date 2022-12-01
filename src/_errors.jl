import Base.StackTraces: StackFrame
import MyterialColors: pink, indigo_light

"""
    function render_frame_info end

Create a Term visualization of info and metadata about a 
stacktrace frame.
"""
function render_frame_info end

function render_frame_info(pointer::Ptr{Nothing}, args...; show_source = true)
    frame = StackTraces.lookup(pointer)[1]
    return render_frame_info(frame, args...; show_source = show_source)
end

function render_frame_info(frame::StackFrame, ; show_source = true)
    theme = TERM_THEME[]

    # get the name of the error function
    func = sprint(StackTraces.show_spec_linfo, frame)
    func = replace(
        func,
        r"(?<group>^[^(]+)" =>
            SubstitutionString("{$(theme.func)}" * s"\g<0>" * "{/$(theme.func)}"),
    )
    func = reshape_text(func, default_stacktrace_width()) |> lstrip

    # get other information about the function 
    inline =
        frame.inlined ? RenderableText("   inlined"; style = "bold dim $(theme.text)") : ""
    c = frame.from_c ? RenderableText("   from C"; style = "bold dim $(theme.text)") : ""
    func_line = hstack(func, inline, c; pad = 1)

    file = Base.fixup_stdlib_path(string(frame.file))
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

"""
    render_backtrace_frame(
        num::RenderableText,
        info::AbstractRenderable;
        as_panel = true,
        kwargs...,
    )

Render a backtrace frame as either a `Panel` or a `RenderableText`
"""
function render_backtrace_frame(
    num::RenderableText,
    info::AbstractRenderable,
    ;
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

"""
    function frame_module end 

Get the Module a function is defined in, as a string
"""
function frame_module(frame::StackFrame)
    m = Base.parentmodule(frame)
    if m !== nothing
        while parentmodule(m) !== m
            pm = parentmodule(m)
            pm == Main && break
            m = pm
        end
    end
    m = !isnothing(m) ? string(m) : frame_module(string(frame.file))

    return m
end

"""
Get module from file path.
"""
frame_module(path::String) = startswith(path, "./") ? "Base" : nothing

"""
    should_skip

A frame should skip if it's in Base or an installed package.
"""
should_skip(frame::StackFrame) =
    frame_module(frame) == "Base" || (
        contains(string(frame.file), r"[/\\].julia[/\\]") ||
        contains(string(frame.file), r"[/\\]julia[/\\]stdlib[/\\]")
    )

"""
    render_backtrace(bt::Vector; reverse_backtrace = true, max_n_frames = 30)

Main error backtrace rendering function. 
It renders each frame in a stacktrace after some filtering (e.g. to hide frames in BASE).
It takes care of hiding frames when there's a large number of them. 
"""
function render_backtrace(
    bt::Vector;
    reverse_backtrace = true,
    max_n_frames = 30,
    hide_base = true,
)
    theme = TERM_THEME[]
    length(bt) == 0 && return RenderableText("")

    if reverse_backtrace
        bt = reverse(bt)
    end

    # get the module each frame's code line is defined in
    frames_modules = frame_module.(bt)

    # render each frame
    content = AbstractRenderable[]
    added_skipped_message = false
    N = length(bt)
    prev_frame_module = nothing # keep track of the previous' frame module
    n_skipped = 0  # keep track of number of frames skipped (e.g in Base)
    skipped_frames_modules = []
    for (num, frame) in enumerate(bt)
        numren = RenderableText("($(num))"; style = "$(theme.emphasis) bold dim")
        info = render_frame_info(frame; show_source = num in (1, length(bt)))

        # if the current frame's module differs from the previous one, show module name
        curr_module = frames_modules[num]
        if curr_module != prev_frame_module
            (curr_module == "Base" && hide_base && num ∉ [1, length(bt)]) || begin
                accent = theme.err_accent
                push!(
                    content,
                    hLine(
                        default_stacktrace_width() - 6,
                        "{default $(theme.text_accent)}In module {$accent bold}$(curr_module){/$accent bold}{/default $(theme.text_accent)}";
                        style = "$accent dim",
                    ),
                )
            end
        end

        if num == 1  # first frame is highlighted
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

        elseif num == length(bt)  # last frame is highlighted
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

        else  # inside frames are printed without an additional panel around

            # skip extra panels for long stack traces
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
            else  # show "inner" frames without additional info, hide base optionally

                # skip frames in modules like Base
                to_skip = should_skip(frame)

                # show number of frames skipped
                if (to_skip == false || num == length(bt) - 1) && n_skipped > 0
                    color = TERM_THEME[].err_btframe_panel
                    accent = TERM_THEME[].err_accent
                    modules = join(unique(string.(skipped_frames_modules)), ", ")
                    push!(
                        content,
                        cvstack(
                            hLine(default_stacktrace_width() - 12; style = "$color dim"),
                            RenderableText(
                                "⋮" /
                                "Skipped {bold}$n_skipped{/bold} frames from {$accent}$modules{/$accent}" /
                                "⋮";
                                width = default_stacktrace_width() - 6,
                                justify = :center,
                                style = color,
                            ),
                            hLine(default_stacktrace_width() - 12; style = "$color dim");
                            pad = 0,
                        ),
                    )
                end

                # skip
                to_skip && begin
                    n_skipped += 1
                    push!(skipped_frames_modules, curr_module)
                    continue
                end

                # show
                n_skipped, skipped_frames_modules = 0, []
                push!(content, render_backtrace_frame(numren, info; as_panel = false))
            end
        end

        prev_frame_module = curr_module
    end

    # create an overall panel
    return Panel(
        cvstack(content..., pad = 1);
        padding = (2, 2, 2, 1),
        subtitle = "Error Stack",
        style = "$(theme.er_bt) dim",
        subtitle_style = "bold $(theme.er_bt) default",
        title = "Error Stack",
        title_style = "bold $(theme.er_bt) default",
        fit = false,
        justifty = :left,
        width = default_stacktrace_width(),
    )
end
