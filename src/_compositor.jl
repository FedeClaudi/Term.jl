
interpolate_from_dict(ex::Expr, dict) =
    Expr(ex.head, interpolate_from_dict.(ex.args, Ref(dict))...)
interpolate_from_dict(ex::Symbol, dict::Dict) = get(dict, ex, ex)
interpolate_from_dict(ex::Any, dict) = ex

layout_simbols = (
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
    parse_single_element_layout(expr::Expr)

Parse an expression with a single layout element, like :(A(25, 5))
"""
function parse_single_element_layout(expr::Expr)
    s, w, h = expr.args
    return [:($s($w, $h))]
end

"""
    collect_elements(exp::Expr)

Collects elements (individual LayoutElements) that are
in a layout expresssion.
"""
function collect_elements(exp::Expr)
    if exp.args[1] ∉ layout_simbols && length(exp.args) > 2
        n, w, h = exp.args
        return :($n($w, $h))
    elseif exp.args[1] ∉ layout_simbols
        return nothing
    else
        symbols = map(x -> x isa Symbol ? x : collect_elements(x), exp.args)
        symbols = filter(s -> s ∉ layout_simbols && !isnothing(s), symbols)
        return reduce(vcat, symbols)
    end
end

function clean_layout_symbol(s::Symbol)
    s[1] ∉ layout_simbols ? s[1] : s
end

function clean_layout_expr(exp::Expr)
    if exp.args[1] ∉ layout_simbols
        return exp.args[1]
    else
        exp.args = map(a -> a isa Expr ? clean_layout_expr(a) : a, exp.args)
    end
    return exp
end

placeholder(s, w, h, c) = PlaceHolder(
    w,
    h;
    style = c,
    text = "{bold underline bright_blue}$s{/bold underline bright_blue} {white}($w × $h){/white}",
)

"""
    extract_renderable_from_kwargs(s, w, h; kwargs...)

When passing kwargs to a `Compositor`, check for renderables that are 
to be assigned to its content.
"""
function extract_renderable_from_kwargs(s, w, h; kwargs...)
    ren = get(kwargs, s, nothing)
    if !isnothing(ren)
        ren = ren isa AbstractRenderable ? ren : RenderableText(ren)

        # check renderable has the right size
        msg = "While creating a Compository layout, the layout element"
        @assert ren.measure.w == w highlight(
            msg * " :$s has width $w but the renderable passed has width $(ren.measure.w)",
        )
        @assert ren.measure.h == h highlight(
            msg *
            " :$s has height $h but the renderable passed has height $(ren.measure.h)",
        )
    end
    return ren
end
