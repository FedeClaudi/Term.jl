import Base.StackTraces: StackFrame


function render_frame_info(frame::StackFrame)::RenderableText
    func = string(frame.func)
    if length(string(frame.file)) > 0
        return RenderableText(
            """   {#ffc44f}$(func){/#ffc44f}
              {dim}$(frame.file):{bold white}$(frame.line){/bold white}{/dim}
            """; width=88
        )
    else
        return RenderableText(
            "   " * func
        )
    end
end


function render_backtrace(bt::Vector{StackFrame})
    length(bt) == 0 && return RenderableText("")

    frame_numbers::Vector{RenderableText} = []
    frame_info::Vector{RenderableText} = []
    frame_inlined::Vector{RenderableText} = []
    frame_from_c::Vector{RenderableText} = []

    emptyren = RenderableText("")
    inlinedren = RenderableText("   inlined"; style="bold blue")
    fromcren = RenderableText("   from C"; style="bold blue")

    for (num, frame) in enumerate(bt)
        push!(frame_numbers, RenderableText("($(num))"; style="#52c4ff bold dim"))
        push!(frame_info, render_frame_info(frame))

        push!(frame_inlined, frame.inlined ? inlinedren : emptyren)
        push!(frame_from_c, frame.from_c ? fromcren : emptyren)
        
    end

    content::Vector{AbstractRenderable} = [
        Panel(
        frame_numbers[1] * frame_info[1] * frame_inlined[1] * frame_from_c[1];
        padding=(2, 2, 1, 1), 
        subtitle="ERROR LINE",
        style="#9bb3e0", 
        subtitle_style="bold white",
        subtitle_justify=:right, width=88
    )]
    
    N = length(frame_numbers)
    if N > 3
        if N > 10
            skipped_line = hLine(
                content[1].measure.w, "{blue dim bold}$(N - 12){/blue dim bold}{blue dim} frames skipped{/blue dim}";
                style="blue dim"
            )

            frames = cvstack(
                vstack(
                    map(x->"   " * hstack(x...), 
                        zip(frame_numbers, frame_info, frame_inlined, frame_from_c))[2:7]...
                ), 
                "", 
                skipped_line, 
                "", 
                vstack(
                    map(x->"   " * hstack(x...), 
                        zip(frame_numbers, frame_info, frame_inlined, frame_from_c))[end-3:end-1]...
                ) 
            )
        else
            frames = vstack(
                map(
                    x->"   " * hstack(x...), 
                    zip(frame_numbers, frame_info, frame_inlined, frame_from_c))[2:end-1]...
                ) 

        end
        push!(content, Spacer(frames.measure.w, 1) / frames)
    elseif N == 3
        push!(content, frame_numbers[2] * frame_info[2] * frame_inlined[2] * frame_from_c[2])
    end

    if N > 1
        push!(content, Panel(
            frame_numbers[end] * frame_info[end] * frame_inlined[end] * frame_from_c[end];
            padding=(2, 2, 1, 1), subtitle="TOP LEVEL", style="#9bb3e0", subtitle_style="white",
            subtitle_justify=:right, width=88
        ))
    end

    return Panel(
        lvstack(content...);
        fit=false, padding=(2, 2, 0, 1), 
        subtitle="Error Stack", style="#ff8a4f dim", subtitle_style="bold #ff8a4f default",
        title="Error Stack",  title_style="bold #ff8a4f default",
        width=40
    )
end