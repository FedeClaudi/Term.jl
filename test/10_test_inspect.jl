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
for (i, e) in enumerate(expressions)
    tofile(string(Dendogram(e)), "./txtfiles/dendo_expr_$i.txt")
    tofile(string(Tree(e)), "./txtfiles/tree_expr_$i.txt")
    tofile(sprint(expressiontree, e), "./txtfiles/exptree_expr_$i.txt")
end

@testset "Inspect: expressions" begin
    if !Sys.iswindows()
        # dendogram
        for (i, e) in enumerate(expressions)
            dendo = Dendogram(e)
            tree = Tree(e)

            @test dendo isa Dendogram
            @test fromfile("./txtfiles/dendo_expr_$i.txt") == cleanstring(dendo)

            @test tree isa Tree
            @test fromfile("./txtfiles/tree_expr_$i.txt") == cleanstring(tree)

            @test fromfile("./txtfiles/exptree_expr_$i.txt") ==
                  cleansprint(expressiontree, e)

            inspect(devnull, e)
        end
        typestree(devnull, Float64)
        redirect_stdout(devnull) do
            typestree(Float64)
            expressiontree(:(1 + 2.0))
        end
    end
end

@testset "Introspect types and funcs" begin
    abstract type Structy end

    struct MyStr <: Structy
        x::Int
        y::Vector
    end
    MyStr(x) = MyStr(x, x)

    dosmth(m::MyStr) = print(m.x)

    # intro = @capture_out begin
    #     inspect(MyStr; methods = true, supertypes = true)
    # end
    # intro = remove_ansi(intro)
    # @test intro isa String

    # intro = @capture_out begin
    #     inspect(Panel; methods = true, supertypes = true,)
    # end
    # @compare_to_string(intro, "introspection_panel")
    # @test_nothrow inspect(Panel; methods = true, supertypes = true)

    intro = @capture_out begin
        inspect(print)
    end
    intro = remove_ansi(intro)
    # @compare_to_string(intro, "introspection_print")
    @test intro isa String
end
