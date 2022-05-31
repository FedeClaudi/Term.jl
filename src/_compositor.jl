
interpolate_from_dict(ex::Expr, dict) = Expr(ex.head, interpolate_from_dict.(ex.args, Ref(dict))...)
interpolate_from_dict(ex::Symbol, dict::Dict) = get(dict, ex, ex)
interpolate_from_dict(ex::Any, dict) = ex


layout_simbols = (Symbol(/), Symbol(*), :vstack, :lvstack, :leftalign, :center, :rightalign, :lvstack, :rvstack, :cvstack)

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
    if exp.args[1]  ∉ layout_simbols 
        return exp.args[1]
    else
        exp.args = map(
            a -> a isa Expr ? clean_layout_expr(a) : a,
            exp.args
        )
    end
    return exp
end
