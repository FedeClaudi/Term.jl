
function repr_get_obj_fields_display(obj)
    field_names = fieldnames(typeof(obj))
    if length(field_names) == 0
        theme = term_theme[]
        return RenderableText(
            "$obj{$(theme.repr_type_style)}::$(typeof(obj)){/$(theme.repr_type_style)}",
        )
        return nothing
    end
    field_types = map(f -> "::" * string(f), typeof(obj).types)
    _values = map(f -> getfield(obj, f), field_names)

    fields = map(
        ft -> RenderableText(
            apply_style(string(ft[1]), term_theme[].repr_accent_style) *
            apply_style(string(ft[2]), term_theme[].repr_type_style),
        ),
        zip(field_names, field_types),
    )

    values = []
    for val in _values
        val = truncate(string(val), 45)
        push!(values, RenderableText.(val; style = term_theme[].repr_values_style))
    end

    line = vLine(length(fields); style = term_theme[].repr_line_style)
    space = Spacer(1, length(fields))

    content = rvstack(fields...) * line * space * lvstack(values...)
    return content
end

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

function repr_panel(
    obj,
    content,
    subtitle;
    width = console_width() - 10,
    justify = :center,
    kwargs...,
)
    p = Panel(
        content;
        fit = true,
        title = isnothing(obj) ? obj : escape_brackets(string(typeof(obj))),
        title_justify = :left,
        width = width,
        justify = justify,
        style = term_theme[].repr_panel_style,
        title_style = term_theme[].repr_name_style,
        padding = (2, 1, 1, 1),
        subtitle = subtitle,
        subtitle_justify = :right,
        kwargs...,
    )

    return p
end

function vec_elems2renderables(v::Union{Tuple,AbstractVector}, N, max_w)
    shortsting(x) = x isa AbstractRenderable ? info(x) : truncate(string(x), max_w)
    out = highlight.(shortsting.(v[1:N]))

    length(v) > N && push!(out, "⋮";)
    return out
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
    counts = "(" .* string.(1:length(vec_items)) .* ")"

    content = Table(
        [counts vec_items];
        show_header = false,
        columns_justify = [:right, :left],
        columns_style = ["dim", "default"],
        columns_widths = [12, 60],
        vpad = 0,
        hpad = 2,
        compact = true,
        box = :NONE,
    )

    # content = rvstack(counts...) * Spacer(3, length(counts)) * cvstack(vec_items)
    return content
end
