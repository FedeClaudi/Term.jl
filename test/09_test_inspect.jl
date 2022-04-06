import Term: inspect, expressiontree, typestree, Dendogram, Tree

println("\nTesting logging, stdout temporarily disabled")
# @suppress_out begin
@testset "\e[34mINSPECT test" begin

    # define some types
    abstract type T1 end

    abstract type T2 <: T1 end

    """
        MyType

    It's just a useless type we've defined to provide an example of
    Term's awesome `inspect` functionality!
    """
    struct MyType <: T2
        x::Int
        y::String
        fn::Any
    end

    #  Now, what is MyType like?
    # tofile(sprint(inspect, MyType), "./txtfiles/inspect_01.txt")
    @test sprint(inspect, MyType) == fromfile("./txtfiles/inspect_01.txt")
    

    # Let's define some constructors and methods using MyType

    """
    constructors!
    """
    MyType(x::Int) = MyType(x, "no string", nothing)

    MyType(x::Int, y) = MyType(x, y, nothing)

    # methods
    useless_method(m::MyType) = m
    another_method(m1::MyType, m2::MyType) = print(m1, m2)

    # let's inspect MyType again!
    # tofile(sprint(inspect, MyType), "./txtfiles/inspect_02.txt")
    @test sprint(inspect, MyType) == fromfile("./txtfiles/inspect_02.txt")


    # other object types
    # tofile(sprint(inspect, 1), "./txtfiles/inspect_03.txt")
    # tofile(sprint(inspect, T2), "./txtfiles/inspect_04.txt")
    # tofile(sprint(inspect, inspect), "./txtfiles/inspect_05.txt")

    @test sprint(inspect, 1) == fromfile("./txtfiles/inspect_03.txt")
    @test sprint(inspect, T2) == fromfile("./txtfiles/inspect_04.txt")
    @test sprint(inspect, inspect) == fromfile("./txtfiles/inspect_05.txt")
end
# end


# define expressions
e1 = :(2x + 3y + 2)
e2 = :(2x + 3 + 2 + 2y)
e3 = :(2x^(3+y))
e4 = :(1 + 1 - 2x^2)
e5 = :(mod(22, 6))
e6 = :(2x^(3+y) + 2z)
e7 = :(2x + 3 * √(3x^2))
e8 = :(print(lstrip("test")))
expressions = (e1, e2, e3, e4, e5, e6, e7, e8)

# save expressions to file (for later comparisons)
# for (i, e) in enumerate(expressions)
#     tofile(string(Dendogram(e)), "./txtfiles/dendo_expr_$i.txt")
#     tofile(string(Tree(e)), "./txtfiles/tree_expr_$i.txt")
#     tofile(sprint(expressiontree, e), "./txtfiles/exptree_expr_$i.txt")
# end



@testset "Inspect: expressions" begin
    # dendogram
    for (i, e) in enumerate(expressions)
        dendo = Dendogram(e)
        tree = Tree(e)

        @test dendo isa Dendogram
        @test fromfile("./txtfiles/dendo_expr_$i.txt") == string(dendo)

        @test tree isa Tree
        @test fromfile("./txtfiles/tree_expr_$i.txt") == string(tree)

        @test fromfile("./txtfiles/exptree_expr_$i.txt") == sprint(expressiontree, e)
    end
    
end



@testset "Inspect: typestree" begin
    @test sprint(typestree, Float64) == "\e[2m\e[34m╭───────────── \e[22m\e[38;2;255;167;38mTypes hierarchy\e[22m\e[39m\e[34m\e[2m\e[34m ───╮\e[22m\e[39m\e[22m\e[39m\e[34m\n\e[2m\e[34m│\e[22m\e[39m                                 \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m  \e[3m\e[38;5;10mAny\e[23m\e[39m                            \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m \e[2m\e[3m\e[38;5;10m━━━━━\e[22m\e[23m\e[39m                           \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[22m                          \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m├── \e[22m\e[39m\e[3m\e[38;2;255;238;88mReal\e[23m\e[39m\e[22m                      \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m├── \e[22m\e[39m\e[3m\e[38;2;255;238;88mAbstractFloat\e[23m\e[39m\e[22m         \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m├── \e[22m\e[39m\e[3m\e[38;2;255;238;88m\e[3m\e[4m\e[38;5;214mFloat64\e[23m\e[24m\e[39m\e[38;2;255;238;88m\e[23m\e[39m\e[22m           \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m├── \e[22m\e[39mBigFloat\e[22m          \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m├── \e[22m\e[39mFloat32\e[22m           \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m└── \e[22m\e[39mFloat16\e[22m           \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m│   \e[22m\e[39m\e[22m                      \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m├── \e[22m\e[39mRational\e[22m              \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m├── \e[22m\e[39mAbstractIrrational\e[22m    \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[2m\e[32m└── \e[22m\e[39mInteger\e[22m               \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m│   \e[22m\e[39m\e[22m                          \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m   \e[22m\e[2m\e[32m└── \e[22m\e[39mComplex\e[22m                   \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m│\e[22m\e[39m                                 \e[0m\e[2m\e[34m│\e[22m\e[39m\e[0m\n\e[2m\e[34m╰─────────────────────────────────╯\e[22m\e[39m\n"
end