import Term.tree: Tree

tree_dict = Dict(
    "nestedasdasdsadasdasdsadsadasdasdasdsadasasdasdassfsdfdsfdsfdsfsdfsdfdsfsdfd" =>
        Dict("n1" => 1, "n2" => 2),
)

tree_dict_1 = Dict(
    "nested" => Dict("n1" => 1, "n2" => 2), "nested2" => Dict("n1" => "a", "n2" => 2)
)

tree_dict_2 = Dict(
    "nested" => Dict("n1" => 1, "n2" => 2),
    "leaf2" => 2,
    "leaf" => 2,
    "leafme" => "v",
    "canopy" => "test",
)

tree_dict_3 = Dict(
    "nested" => Dict(
        "deeper" => Dict("aleaf" => "unbeliefable", "leaflet" => "level 3"),
        "n2" => Int,
        "n3" => 1 + 2,
    ),
    "nested2" => Dict("n1" => "a", "n2" => 2),
)

tree_dict_4 = Dict(
    "nested" => Dict(
        "deeper" => Dict(
            "aleaf" => "unbeliefable",
            "leaflet" => "level 3",
            "sodeep" => Dict("a" => 4),
        ),
        "n2" => Int,
        "n3" => 1 + 2,
        "adict" => Dict("x" => 2),
    ),
    "nested2" => Dict("n1" => "a", "n2" => 2),
)

@testset "\e[34mTree" begin
    # creation
    testtree(Tree(tree_dict), 50, 6)

    testtree(Tree(tree_dict_1), 15, 9)

    testtree(Tree(tree_dict_2), 18, 11)

    testtree(Tree(tree_dict_3), 33, 13)

    testtree(Tree(tree_dict_4), 33, 19)

    # styling
    for guides_type in (:standardtree, :boldtree, :asciitree)
        @test_nothrow Tree(
            tree_dict; title = string(guides_type), guides_type = guides_type
        )
    end

    testtree(
        Tree(
            tree_dict;
            title = "my colors",
            title_style = "bold red",
            node_style = "blue underline",
            leaf_style = "green",
            guides_style = "red dim",
        ),
        52,
        6,
    )

    # test with no errors
    @test_nothrow Tree(Float64)
    @test_nothrow Tree(AbstractFloat)
end
