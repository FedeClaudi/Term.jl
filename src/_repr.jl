import Term: default_width
import OrderedCollections: OrderedDict

function repr_get_obj_fields_display(obj)
    theme = TERM_THEME[]

    field_names = fieldnames(typeof(obj))
    length(field_names) == 0 && return RenderableText(
        "$obj{$(theme.repr_type)}::$(typeof(obj)){/$(theme.repr_type)}",
    )
    field_types = map(f -> "::" * string(f), typeof(obj).types)
    _values = map(f -> getfield(obj, f), field_names)

    fields = map(
        ft -> RenderableText(
            apply_style(string(ft[1]), theme.repr_accent) *
            apply_style(string(ft[2]), theme.repr_type),
        ),
        zip(field_names, field_types),
    )

    values = []
    for val in _values
        val = str_trunc(string(val), 45)
        push!(values, RenderableText.(val; style = theme.repr_values))
    end

    return Table(
        OrderedDict(:field => fields, :value => values);
        hpad = 0,
        box = :NONE,
        show_header = false,
        compact = true,
    )
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

"""
Create a Panel showing repr content using the current theme's style info.
"""
repr_panel(
    obj,
    content,
    subtitle;
    width = min(console_width() - 10, default_width()),
    justify = :center,
    kwargs...,
) = Panel(
    content;
    fit = true,
    title = isnothing(obj) ? obj : escape_brackets(string(typeof(obj))),
    title_justify = :left,
    width = width,
    justify = justify,
    style = TERM_THEME[].repr_panel,
    title_style = TERM_THEME[].repr_name,
    padding = (1, 1, 1, 1),
    subtitle = subtitle,
    subtitle_justify = :right,
    kwargs...,
)

function vec_elems2renderables(v::Union{Tuple,AbstractVector}, N, max_w; ellipsis = false)
    v = Vector(v)  # necessary to handle sparse vectors
    shortsting(x) =
        x isa AbstractRenderable ? info(x) : remove_markup(str_trunc(string(x), max_w))
    out = highlight.(shortsting.(v[1:N]))

    ellipsis && length(v) > N && push!(out, " ⋮";)
    return out
end

function matrix2content(mtx::AbstractMatrix; max_w = 12, max_items = 50, max_D = 10)
    max_D = if console_width() > 150
        max_D
    elseif console_width() < 80
        3
    else
        5
    end

    N = min(max_items, size(mtx, 1))
    D = min(max_D, size(mtx, 2))

    _D = size(mtx, 2) > max_D ? D - 1 : D
    columns = [vec_elems2renderables(mtx[:, i], N, max_w; ellipsis = true) for i in 1:_D]

    # add a column of ellipses
    if size(mtx, 2) > max_D
        c = repeat(["⋯"], length(columns[1]) - 1)
        push!(c, size(mtx, 1) <= max_items ? "⋯" : "⋱")
        push!(columns, c)

        headers = "(" .* string.(1:(length(columns) - 1)) .* ")" |> collect
        push!(headers, "($(size(mtx, 2)))")
    else
        headers = "(" .* string.(1:length(columns)) .* ")" |> collect
    end

    # add a column of row numbers
    if size(mtx, 1) <= max_items
        pushfirst!(columns, "{dim}(" .* string.(1:length(columns[1])) .* "){/dim}")
    else
        nums = "{dim}(" .* string.(1:(length(columns[1]) - 1)) .* "){/dim}"
        push!(nums, "")
        pushfirst!(columns, nums)
    end
    pushfirst!(headers, "")

    content = Table(
        OrderedDict(map(i -> headers[i] => columns[i], 1:length(columns)));
        vpad = 0,
        hpad = 1,
        compact = true,
        box = :NONE,
        header_style = "dim",
        header_justify = :center,
        columns_justify = :left,
    )
    return content
end

function vec2content(vec::Union{Tuple,AbstractVector})
    max_w = default_width()
    max_items = 50
    N = min(max_items, length(vec))

    N == 0 && return "{bright_blue}empty vector{/bright_blue}"

    vec_items = vec_elems2renderables(vec, N, max_w)
    counts = "(" .* string.(1:length(vec_items)) .* ")"

    length(vec) > N && begin
        push!(vec_items, " ⋮";)
        push!(counts, "";)
    end

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
        methods_texts = map(m -> reshape_code_string(m, width - 30), _methods)

        vstack(map(i -> counts[i] * methods_texts[i], 1:length(counts))...)
    else
        fun |> methods |> string |> split_lines |> first
    end

    return methods_contents, N
end
