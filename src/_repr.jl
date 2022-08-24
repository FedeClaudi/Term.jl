import Term: default_width

function repr_get_obj_fields_display(obj)
    field_names = fieldnames(typeof(obj))
    theme = TERM_THEME[]
    length(field_names) == 0 && return RenderableText(
        "$obj{$(theme.repr_type_style)}::$(typeof(obj)){/$(theme.repr_type_style)}",
    )
    field_types = map(f -> "::" * string(f), typeof(obj).types)
    _values = map(f -> getfield(obj, f), field_names)

    fields = map(
        ft -> RenderableText(
            apply_style(string(ft[1]), theme.repr_accent_style) *
            apply_style(string(ft[2]), theme.repr_type_style),
        ),
        zip(field_names, field_types),
    )

    values = []
    for val in _values
        val = str_trunc(string(val), 45)
        push!(values, RenderableText.(val; style = theme.repr_values_style))
    end

    line = vLine(length(fields); style = theme.repr_line_style)
    space = Spacer(length(fields), 1)

    return rvstack(fields...) * line * space * lvstack(values...)
end

"""
    typename(typedef::Expr)

Get the name of a type as an expression
"""
typename(typedef::Expr) =
    if typedef.args[2] isa Symbol
        typedef.args[2]
    elseif typedef.args[2].args[1] isa Symbol
        typedef.args[2].args[1]
    elseif typedef.args[2].args[1].args[1] isa Symbol
        typedef.args[2].args[1].args[1]
    else
        error("Could not parse type-head from: $typedef")
    end

repr_panel(
    obj,
    content,
    subtitle;
    width = min(console_width() - 10, default_width()),
    justify = :center,
    kwargs...,
) = Panel(
    content;
    fit = false,
    title = isnothing(obj) ? obj : escape_brackets(string(typeof(obj))),
    title_justify = :left,
    width = width,
    justify = justify,
    style = TERM_THEME[].repr_panel_style,
    title_style = TERM_THEME[].repr_name_style,
    padding = (2, 1, 1, 1),
    subtitle = subtitle,
    subtitle_justify = :right,
    kwargs...,
)

function vec_elems2renderables(v::Union{Tuple,AbstractVector}, N, max_w)
    shortsting(x) = x isa AbstractRenderable ? info(x) : str_trunc(string(x), max_w)
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

    space1, space2 = Spacer(length(counts), 3), Spacer(length(counts), 2)

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
    max_w = default_width()
    max_items = 100
    N = min(max_items, length(vec))

    N == 0 && return "{bright_blue}empty vector{/bright_blue}"

    vec_items = vec_elems2renderables(vec, N, max_w)
    counts = "(" .* string.(1:length(vec_items)) .* ")"

    content = Table(
        [counts vec_items];
        show_header = false,
        columns_justify = [:right, :left],
        columns_style = ["dim", "default"],
        # columns_widths = [12, 60],
        vpad = 0,
        hpad = 2,
        compact = true,
        box = :NONE,
    )

    # content = rvstack(counts...) * Spacer(length(counts), 3) * cvstack(vec_items)
    return content
end

style_function_methods(fun; kwargs...) =
    style_function_methods(fun, methods(fun); kwargs...)

style_function_methods(fun, _methods::Base.MethodList; kwargs...) =
    style_function_methods(fun, string(_methods); kwargs...)

"""
Create a styled list of methods for a function.
Accepts `string(methods(function))` as argument.
"""
function style_function_methods(fun, methods::String; max_n = 11, width = default_width())
    _methods = split_lines(methods)
    N = length(_methods)

    _methods = length(_methods) > 1 ? _methods[2:min(max_n, N)] : []
    _methods = map(m -> join(split(join(split(m, "]")[2:end]), " in ")[1]), _methods)
    _methods = map(
        m -> replace(
            m,
            string(fun) => "{bold #a5c6d9}$(string(fun)){/bold #a5c6d9}";
            count = 1,
        ),
        _methods,
    )
    counts = RenderableText.("(" .* string.(1:length(_methods)) .* ") "; style = "bold dim")
    if (m = N - length(_methods) - 1) > 0
        push!(
            _methods,
            "\n{bold dim bright_blue}$m{/bold dim bright_blue}{dim bright_blue} $(plural("method", m)) omitted...{/dim bright_blue}",
        )
    end
    methods_contents = if N > 1
        methods_texts = RenderableText.(highlight.(_methods); width = width - 20)
        join(string.(map(i -> counts[i] * methods_texts[i], 1:length(counts))), '\n')
    else
        fun |> methods |> string |> split_lines |> first
    end
    return methods_contents, N
end
