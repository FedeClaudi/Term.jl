
interpolate_from_dict(ex::Expr, dict) =
    Expr(ex.head, interpolate_from_dict.(ex.args, Ref(dict))...)
interpolate_from_dict(ex::Symbol, dict::Dict) = get(dict, ex, ex)
interpolate_from_dict(ex::Any, dict) = ex

layout_symbols = (
    Symbol(/),
    Symbol(*),
    :vstack,
    :lvstack,
    :leftalign,
    :hstack,
    :center,
    :rightalign,
    :lvstack,
    :rvstack,
    :cvstack,
    :pad,
    :pad!,
    :vertical_pad,
    :vertical_pad!,
)

"""
    parse_single_element_layout(ex::Expr)

Parse an expression with a single layout element, like :(A(5, 25)) or :(A)
"""
function parse_single_element_layout(ex::Expr)
    if length(ex.args) == 3
        s, h, w = ex.args
    else
        s = ex.args[1]
        h, w = default_size()
    end
    return [:($s($h, $w))]
end

"""
    get_elements_and_sizes(ex::Expr)

Get elements names and sizes.
"""
function get_elements_and_sizes(ex::Expr; placeholder_size = nothing)
    elements = collect_elements(ex)
    elements = elements isa Expr ? parse_single_element_layout(elements) : elements
    min_h = min_w = typemax(Int)
    for e in elements
        e isa Symbol && continue

        h, w = e.args[2], e.args[3]
        h = h isa Int ? h : fint(console_height() * h)
        w = w isa Int ? w : fint(console_width() * w)
        min_h = min(min_h, h)
        min_w = min(min_w, w)
    end

    # fallback size
    h, w = something(placeholder_size, default_size())
    min_h == typemax(Int) && (min_h = h)
    min_w == typemax(Int) && (min_w = w)

    return [e isa Symbol ? :($e($min_h, $min_w)) : e for e in elements]
end

"""
    collect_elements(ex::Expr)

Collects elements (individual LayoutElements) that are
in a layout expresssion.
"""
function collect_elements(ex::Expr)
    if ex.args[1] ∉ layout_symbols
        return if length(ex.args) > 2
            s, h, w = ex.args
            :($s($h, $w))
        else
            nothing
        end
    else
        symbols = map(x -> x isa Symbol ? x : collect_elements(x), ex.args)
        symbols = filter(s -> s ∉ layout_symbols && !isnothing(s), symbols)
        return reduce(vcat, symbols)
    end
end

function clean_layout_expr(ex::Expr)
    if ex.args[1] ∉ layout_symbols
        return ex.args[1]
    else
        ex.args = map(a -> a isa Expr ? clean_layout_expr(a) : a, ex.args)
    end
    return ex
end

compositor_placeholder(s, h, w, c) = begin
    h = h isa Int ? h : fint(console_height() * h)
    w = w isa Int ? w : fint(console_width() * w)
    PlaceHolder(
        h,
        w;
        style = c,
        text = "{bold underline bright_blue}$s{/bold underline bright_blue} {white}($h × $w){/white}",
    )
end

"""
    extract_renderable_from_kwargs(s, h, w; kwargs...)

When passing kwargs to a `Compositor`, check for renderables that are 
to be assigned to its content.
"""
function extract_renderable_from_kwargs(s, h, w; check = true, kwargs...)
    ren = get(kwargs, s, nothing)
    if !isnothing(ren)
        ren = ren isa AbstractRenderable ? ren : RenderableText(ren)

        # check renderable has the right size
        if check
            msg = "While creating a Compository layout, the layout element"
            @assert ren.measure.h == h highlight(
                "$msg :$s has height $h but the renderable passed has height $(ren.measure.h)",
            )
            @assert ren.measure.w == w highlight(
                "$msg :$s has width $w but the renderable passed has width $(ren.measure.w)",
            )
        end
    end
    return ren
end
