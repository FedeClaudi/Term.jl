import Base.StackTraces: StackFrame
import MyterialColors: pink, indigo_light
import Term: read_file_lines

"""
    show_error_code_line(frame::StackFrame; δ=2)

Create a `Panel` showing formatted Julia code for a frame's error line. 
The parameter `δ` speciies how many lines above/below the error line to show. 
When δ = 0 only the error line is shown and the panel's style is altered
"""
function show_error_code_line(frame::StackFrame; δ = 2)
    theme = TERM_THEME[]
    error_source = nothing
    try
        error_source = load_code_and_highlight(string(frame.file), Int(frame.line); δ = δ)
    catch
        error_source = nothing
    end

    (isnothing(error_source) || length(error_source) == 0) && return nothing

    _width = min(60, default_stacktrace_width() - (δ > 0 ? 30 : 12))
    code_error_panel = Panel(
        str_trunc(error_source, _width; ignore_markup = true);
        fit = δ == 0,
        style = δ > 0 ? "$(theme.text_accent) dim" : "dim",
        width = _width,
        subtitle_justify = :center,
        subtitle = δ > 0 ? "error line" : nothing,
        subtitle_style = "default $(theme.text_accent)",
        height = δ > 0 ? nothing : 1,
        padding = δ == 0 ? (0, 1, 0, 0) : (2, 2, 0, 0),
        # background = δ > 0 ? nothing : theme.md_codeblock_bg
    )

    code_error_panel = "  " * RenderableText("│\n╰─"; style = "dim") * code_error_panel

    return code_error_panel
end

"""
    parse_kw_func_name(frame::StackFrame)

Kw function calls have a weird name, just show the func definition line.
"""
function parse_kw_func_name(frame::StackFrame)
    linfo = frame.linfo
    def = linfo.def
    if isa(def, Method)
        sig = linfo.specTypes
        argnames = Base.method_argnames(def)
        ftypes = map(i -> fieldtype(sig, i), 1:length(argnames)) |> collect

        kwargs = map(
            i -> fieldname(ftypes[2], i) => fieldtype(ftypes[2], 1),
            1:length(fieldnames(ftypes[2])),
        )

        func = replace(string(def.name), "##kw" => "") * "("
        func *= join(
            map(i -> string(argnames[i]) * "::" * string(ftypes[i]), 4:length(ftypes)),
            ", ",
        )
        !isempty(kwargs) && begin
            func *= "; " * join(["$k::$v" for (k, v) in kwargs], ", ")
        end
        func *= ")"
    else
        func = string(sprint(StackTraces.show_spec_linfo, frame))
    end
    return func
end

"""
    function render_frame_info end

Create a Term visualization of info and metadata about a 
stacktrace frame.
"""
function render_frame_info end

function render_frame_info(pointer::Ptr{Nothing}, args...; show_source = true, kwargs...)
    frame = StackTraces.lookup(pointer)[1]
    return render_frame_info(frame, args...; show_source = show_source, kwargs...)
end

function render_frame_info(frame::StackFrame; show_source = true, kwargs...)
    theme = TERM_THEME[]

    # get the name of the error function
    func = sprint(StackTraces.show_spec_linfo, frame)
    (contains(func, "##kw") || contains(func, "kwerr")) &&
        (func = parse_kw_func_name(frame))

    # format function name
    func = replace(
        func,
        r"(?<group>^[^(]+)" =>
            SubstitutionString("{$(theme.func)}" * s"\g<0>" * "{/$(theme.func)}"),
    )
    func = highlight(func) |> apply_style

    # get other information about the function 
    inline =
        frame.inlined ? RenderableText("   inlined"; style = "bold dim $(theme.text)") : ""
    c = frame.from_c ? RenderableText("   from C"; style = "bold dim $(theme.text)") : ""

    func =
        str_trunc(func, default_stacktrace_width() - 25; ignore_markup = true) |>
        RenderableText
    # func = RenderableText(
    #     apply_style(string(func)); 
    #     width= default_stacktrace_width() - 30
    # )
    func_line = (frame.inlined || frame.from_c) ? func / hstack(inline, c; pad = 1) : func
    func_line = func_line |> string |> apply_style |> remove_markup

    # load source code around error and render it
    if length(string(frame.file)) > 0
        file = Base.fixup_stdlib_path(string(frame.file))
        Base.stacktrace_expand_basepaths() &&
            (file = something(Base.find_source_file(file), file))
        Base.stacktrace_contract_userdir() && (file = Base.contractuser(file))
        file_line = RenderableText(
            "{dim}$(file):{bold $(theme.text_accent)}$(frame.line){/bold $(theme.text_accent)}{/dim}";
            width = default_stacktrace_width() - 30,
        )

        out = func_line / file_line
        if show_source
            error_source = show_error_code_line(frame; kwargs...)
            isnothing(error_source) || (out /= error_source)
        end
        return out
    else
        return RenderableText(func; width = default_stacktrace_width() - 30)
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
            padding = (2, 2, 0, 0),
            style = TERM_THEME[].err_btframe_panel,
            fit = false,
            width = default_stacktrace_width() - 12,
            kwargs...,
        )
    else
        "   " * RenderableText(string(content), width = default_stacktrace_width() - 12)
    end
end

"""
    function frame_module end 

Get the Module a function is defined in, as a string
"""
function frame_module(frame::StackFrame)::Union{Nothing,String}
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
Get module for a pointer obj
"""
frame_module(pointer::Ptr) = frame_module(StackTraces.lookup(pointer)[1])
frame_module(iip::Base.InterpreterIP) = string(iip.mod)

"""
    should_skip

A frame should skip if it's in Base or an installed package.
"""
should_skip(frame::StackFrame) =
    frame_module(frame) == "Base" || (
        contains(string(frame.file), r"[/\\].julia[/\\]") ||
        contains(string(frame.file), r"julia[/\\]stdlib") ||
        contains(string(frame.file), r"julia[/\\]lib") ||
        contains(string(frame.file), r"julialang.language")
    )

should_skip(frame::StackFrame, hide::Bool) = hide ? should_skip(frame) : false
should_skip(pointer::Ptr) = should_skip(StackTraces.lookup(pointer)[1])
should_skip(pointer::Ptr, hide::Bool) = hide ? should_skip(pointer) : false
should_skip(iip::Base.InterpreterIP) = true
should_skip(iip::Base.InterpreterIP, hide::Bool) = true

"""
    add_new_module_name!(content, curr_modul)

When a frame belonging to a module different from the previous one is shown, 
print the new module's name.
"""
function add_new_module_name!(content, curr_module)
    theme = TERM_THEME[]
    accent = theme.err_accent
    push!(
        content,
        hLine(
            default_stacktrace_width() - 8,
            "{default $(theme.text_accent)}In module {$accent bold}$(curr_module){/$accent bold}{/default $(theme.text_accent)}";
            style = "$accent dim",
        ),
    )
end

"""
    add_number_frames_skipped!(content, to_skip, num, bt, n_skipped, skipped_frames_modules)

Add some text explaining how many frames were skipped from the stacktrace visualization
and to which modules they belonged. 
"""
function add_number_frames_skipped!(
    content,
    to_skip,
    num,
    bt,
    n_skipped,
    skipped_frames_modules,
)
    if (to_skip == false || num == length(bt) - 1) && n_skipped > 0
        color = TERM_THEME[].err_btframe_panel
        accent = TERM_THEME[].err_accent
        modules = join(unique(string.(filter(!isnothing, skipped_frames_modules))), ", ")

        modules = filter(x -> x != "nothing", modules)
        in_mod = length(modules) == 0 ? "" : "in {$accent}$modules{/$accent}"
        word = plural("frame", length(modules))
        push!(
            content,
            cvstack(
                hLine(default_stacktrace_width() - 10; style = "$color dim"),
                RenderableText(
                    "Skipped {bold}$n_skipped{/bold} $word $in_mod";
                    width = default_stacktrace_width() - 20,
                    justify = :center,
                    style = color,
                ),
                hLine(default_stacktrace_width() - 10; style = "$color dim");
                pad = 0,
            ),
        )
    end
end

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
    hide_frames = true,
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
    tot_frames_added = 0
    for (num, frame) in enumerate(bt)
        numren = RenderableText("($(num))"; style = "$(theme.emphasis) bold dim")
        δ = num in (1, length(bt)) ? 2 : 0
        info = render_frame_info(
            frame;
            show_source = !should_skip(frame) || num in (1, length(bt)),
            δ = δ,
        )

        # if the current frame's module differs from the previous one, show module name
        curr_module = frames_modules[num]
        (
            curr_module != prev_frame_module &&
            !should_skip(frame, hide_frames) &&
            !isnothing(curr_module)
        ) && add_new_module_name!(content, curr_module)

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
            tot_frames_added += 1

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
            tot_frames_added += 1

        else  # inside frames are printed without an additional panel around
            # skip extra panels for long stack traces
            if tot_frames_added > max_n_frames && num < length(bt) - 5
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
                to_skip = should_skip(frame, hide_frames)

                # show number of frames skipped
                if (to_skip == false || num == length(bt) - 1) && n_skipped > 0
                    add_number_frames_skipped!(
                        content,
                        to_skip,
                        num,
                        bt,
                        n_skipped,
                        skipped_frames_modules,
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
                tot_frames_added += 1
            end
        end

        isnothing(curr_module) || (prev_frame_module = curr_module)
    end

    # create an overall panel
    return Panel(
        cvstack(content..., pad = 1);
        padding = (2, 2, 1, 1),
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
