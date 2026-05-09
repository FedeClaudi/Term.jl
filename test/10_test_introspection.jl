import Term: inspect, expressiontree, typestree, Dendogram, Tree
import Term.Consoles: console_width
import Term: remove_ansi

# define expressions
e1 = :(2x + 3y + 2)
e2 = :(2x + 3 + 2 + 2y)
e3 = :(2x^(3 + y))
e4 = :(1 + 1 - 2x^2)
e5 = :(mod(22, 6))
e6 = :(2x^(3 + y) + 2z)
e7 = :(2x + 3 * √(3x^2))
e8 = :(print(lstrip("test")))
expressions = (e1, e2, e3, e4, e5, e6, e7, e8)

# save expressions to file (for later comparisons)
if !(Base.get_bool_env("CI", false) || Base.get_bool_env("PKGEVAL", false) || Base.get_bool_env("JULIA_PKGEVAL", false))
    for (i, e) in enumerate(expressions)
        tofile(string(Dendogram(e)), "./txtfiles/dendo_expr_$i.txt")
        tofile(string(Tree(e)), "./txtfiles/tree_expr_$i.txt")
        tofile(sprint((io, e) -> show(io, expressiontree(e)), e), "./txtfiles/exptree_expr_$i.txt")
    end
end

@testset "Inspect: expressions" begin
    for (i, e) in enumerate(expressions)
        dendo = Dendogram(e)
        tree = Tree(e)

        @test dendo isa Dendogram
        IS_WIN || @test fromfile("./txtfiles/dendo_expr_$i.txt") == cleanstring(dendo)

        @test tree isa Tree
        IS_WIN || @test fromfile("./txtfiles/tree_expr_$i.txt") == cleanstring(tree)

        IS_WIN || @test fromfile("./txtfiles/exptree_expr_$i.txt") == cleansprint((io, e) -> show(io, expressiontree(e)), e)

        show(devnull, inspect(e))
    end
end

IS_WIN || @testset "Introspect types" begin
    @compare_to_string typestree(Integer, prefix = "xxxx") "typestree_Integer"
    @compare_to_string typestree(Integer, prefix = "xxxx") "typestree_Integer_prefix"

    @compare_to_string typestree(AbstractFloat, prefix = "xxxx") "typestree_AbstractFloat"
    @compare_to_string typestree(AbstractFloat, prefix = "xxxx") "typestree_AbstractFloat_prefix"

    @compare_to_string typestree(Int64) "typestree_Int64"
    @compare_to_string typestree(Float64) "typestree_Float64"
end

abstract type Structy end

struct MyStr <: Structy
    x::Int
    y::Vector
end
MyStr(x) = MyStr(x, x)
dosmth(m::MyStr) = print(m.x)

@testset "Introspect custom types and funcs" begin
    # intro = @capture_out inspect(MyStr)
    # IS_WIN || @compare_to_string intro "introspection_MyStr"

    # intro = @capture_out inspect(Panel)
    # IS_WIN || @compare_to_string intro "introspection_Panel"

    intro = @capture_out inspect(print)
    IS_WIN || @compare_to_string remove_ansi(intro) "introspection_print"
end
