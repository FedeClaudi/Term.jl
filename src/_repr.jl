"""
    typename(typedef::Expr)

Get the name of a type as an expression
"""
function typename(typedef::Expr)
    if typedef.args[2] isa Symbol
        return typedef.args[2]
    elseif typedef.args[2].args[1] isa Symbol
        return typedef.args[2].args[1]
    elseif typedef.args[2].args[1].args[1] isa Symbol
        return typedef.args[2].args[1].args[1]
    else
        error("Could not parse type-head from: $typedef")
    end
end

function repr_panel(obj, content, subtitle; width = 40, kwargs...)
    p = Panel(
        content;
        fit = false,
        title = isnothing(obj) ? obj : escape_brackets(string(typeof(obj))),
        title_justify = :left,
        width = width,
        justify = :center,
        style = term_theme[].repr_panel_style,
        title_style = term_theme[].repr_name_style,
        padding = (2, 2, 1, 1),
        subtitle = subtitle,
        subtitle_justify = :right,
        kwargs...,
    )

    w = console_width() - 10
    if p.measure.w > w
        p = do_by_line(l -> truncate(l, w + 6; trailing_dots = ""), string(p))
    end
    return p
end

function vec_elems2renderables(v::Union{Tuple,AbstractVector}, N, max_w)
    shortsting(x) = truncate(string(x), max_w)
    out = RenderableText.(highlight.(shortsting.(v[1:N])))

    length(v) > N && push!(out, RenderableText("⋮";))
    return cvstack(out...)
end

function matrix2content(mtx::AbstractMatrix; max_w = 12, max_items = 100, max_D = 10)
    max_D = console_width() < 150 ? 5 : max_D
    N = min(max_items, size(mtx, 1))
    D = min(max_D, size(mtx, 2))

    columns = [vec_elems2renderables(mtx[:, i], N, max_w) for i in 1:D]
    counts = RenderableText.("(" .* string.(1:N) .* ")"; style = "dim")
    top_counts = RenderableText.("(" .* string.(1:D) .* ")"; style = "dim white bold")

    space1, space2 = Spacer(3, length(counts)), Spacer(2, length(counts))

    content = ("" / "" / rvstack(counts...)) * space1
    for i in 1:(D - 1)
        content *= cvstack(top_counts[i], "", lvstack(columns[i])) * space2
    end
    content *= cvstack(top_counts[end], "", lvstack(columns[end]))

    if D < size(mtx, 2)
        content *= "" / "" / vstack((" {bold}⋯{/bold}" for i in 1:N)...)
    end
    return content
end

function vec2content(vec::Union{Tuple,AbstractVector})
    max_w = 88
    max_items = 100
    N = min(max_items, length(vec))

    if N == 0
        return "{bright_blue}empty vector{/bright_blue}"
    end

    vec_items = vec_elems2renderables(vec, N, max_w)
    counts = RenderableText.("(" .* string.(1:N) .* ")"; style = "dim")

    content = rvstack(counts...) * Spacer(3, length(counts)) * cvstack(vec_items)
    return content
end
