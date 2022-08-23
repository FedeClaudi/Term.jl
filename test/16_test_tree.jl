import Term: Tree
import OrderedCollections: OrderedDict

tree_dict = Dict(
    "nestedasdasdsadasdasdsadsadasdasdasdsadasasdasdassfsdfdsfdsfdsfsdfsdfdsfsdfd" =>
        Dict("n1" => 1, "n2" => 2),
)

tree_dict_1 =
    Dict("nested" => Dict("n1" => 1, "n2" => 2), "nested2" => Dict("n1" => "a", "n2" => 2))

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


tree_dict_order_1 =     OrderedDict(
    3 => OrderedDict(
        3 => 8,  
        1 => "a"
    ), 
    2 => OrderedDict(
        3 => 8,  
        1 => "a"
    )
)

tree_dict_order_2 =     OrderedDict(
    2 => 1,
    3 => OrderedDict(
            4 => 2,
            "a" => 2,  
            "b" => 1
        ), 

    )

@testset "\e[34mTree" begin
    # creation
    @testtree(Tree(tree_dict), 6, 50)

    @testtree(Tree(tree_dict_1), 9, 15)

    @testtree(Tree(tree_dict_2), 10, 18)

    @testtree(Tree(tree_dict_3), 12, 33)

    @testtree(Tree(tree_dict_4), 16, 33)

    @testtree(Tree(tree_dict_order_1), 9, 14)
    @testtree(Tree(tree_dict_order_2), 8, 14)

    # styling
    for guides_type in (:standardtree, :boldtree, :asciitree)
        @test_nothrow Tree(
            tree_dict;
            title = string(guides_type),
            guides_type = guides_type,
        )
    end

    @testtree(
        Tree(
            tree_dict;
            title = "my colors",
            title_style = "bold red",
            node_style = "blue underline",
            leaf_style = "green",
            guides_style = "red dim",
        ),
        6,
        52,
    )

    # test with no errors
    @test_nothrow Tree(Float64)
    @test_nothrow Tree(AbstractFloat)

    # compare to string
    compare_to_string(Tree(tree_dict), "tree_1")
    compare_to_string(Tree(tree_dict_1), "tree_2")
    compare_to_string(Tree(tree_dict_2), "tree_3")
    compare_to_string(Tree(tree_dict_3), "tree_4")
    compare_to_string(Tree(tree_dict_order_1), "tree_5")
    compare_to_string(Tree(tree_dict_order_2), "tree_6")
end
