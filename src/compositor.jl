using Term


install_term_repr()
install_term_logger()
install_term_stacktrace()

import OrderedCollections: OrderedDict
import Term.Console: console_width, console_height
import Term.Layout: PlaceHolder, vstack, hstack
import Term.Measures: width, height
import Term.Renderables: AbstractRenderable
import Term: do_by_line, CODES_16BIT_COLORS, int, ltrim_str
import Term.Segments: Segment
import Term.Repr: @with_repr

import Term: inspect


import MyterialColors: Palette, blue, pink


print("\n"^10)

mutable struct LayoutElement
    id::Symbol
    w::Int
    h::Int
    renderable::Union{String, AbstractRenderable}
end

mutable struct Layout
    layout::Expr
    elements::Dict{Symbol, LayoutElement}
end

function Layout(layout::Expr)
    # get elements names and sizes
    elements = collect_elements(layout)

    # create renderables
    colors = getfield.(Palette(blue, pink; N=length(elements)).colors, :string)
    renderables = Dict(
            s.args[1]=>PlaceHolder(
                s.args[2], s.args[3]; style=c, text=string(s.args[1]), 
            ) 
            for (c,s) in zip(colors, elements)
    )

    # craete layout elements
    layout_elements = Dict(
        s.args[1] => LayoutElement(
            s.args[1], s.args[2], s.args[3], renderables[s.args[1]],
        ) for s in elements
    )

    return Layout(clean_layout_expr(layout), layout_elements)
end


function render(layout::Layout)
    # evaluate layout
    elements = getfield.(values(layout.elements), :id)
    renderables = getfield.(values(layout.elements), :renderable)

    components = Dict(e => r for (e,r) in zip(elements, renderables))
    ex = interpolate_from_dict(layout.layout, components)
    return eval(:(a = $ex))
end

Base.string(layout::Layout) = string(render(layout))

function Base.print(io::IO, layout::Layout; highlight = true)
    return println(io, string(layout))
end

function Base.show(io::IO, ::MIME"text/plain", layout::Layout)
    print(io, string(layout))
end


interpolate_from_dict(ex::Expr, dict) = Expr(ex.head, interpolate_from_dict.(ex.args, Ref(dict))...)
interpolate_from_dict(ex::Symbol, dict::Dict) = get(dict, ex, ex)
interpolate_from_dict(ex::Any, dict) = ex


function collect_elements(exp::Expr)
    if exp.args[1] ∉ (Symbol(/), Symbol(*))
        n, w, h = exp.args
        return :($n($w, $h))
    else
        symbols = map(x -> x isa Symbol ? x : collect_elements(x), exp.args)
        symbols = filter(s -> s ∉ (Symbol(/), Symbol(*)), symbols)
        return reduce(vcat, symbols)
    end
end

function clean_layout_symbol(s::Symbol) 
    s[1] ∉ (Symbol(/), Symbol(*)) ? s[1] : s
end

function clean_layout_expr(exp::Expr)
    if exp.args[1]  ∉ (Symbol(/), Symbol(*)) 
        return exp.args[1]
    else
        exp.args = map(
            a -> a isa Expr ? clean_layout_expr(a) : a,
            exp.args
        )
    end

    return exp
end






# tODO pass renderables as KW
# TODO make layout store LayoutELement types that can be modified



layout = :(
    (A(25, 5) * B(25, 5)) / 
    C(50, 10) / 
    # (D(25, 5) * E[25, 5]) /
    (D(13, 10) * E(14, 10) * F(15, 10))
)



print(Layout(layout))
print(hLine(50))

# A = PlaceHolder(30, 10, "red")
# B = PlaceHolder(30, 10, "green")
# C = PlaceHolder(60, 10, "blue")

# eval(layout)