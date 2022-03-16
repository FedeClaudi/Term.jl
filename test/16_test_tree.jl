import Term.tree: Tree



tree_dict = Dict(
    "nestedasdasdsadasdasdsadsadasdasdasdsadasasdasdassfsdfdsfdsfdsfsdfsdfdsfsdfd" => Dict(
        "n1"=>1,
        "n2"=>2,
    ),  
)

tree_dict_1 = Dict(
    "nested" => Dict(
        "n1"=>1,
        "n2"=>2,
    ),  
    "nested2" => Dict(
        "n1"=>"a",
        "n2"=>2,
    ),  
)

tree_dict_2 = Dict(
    "nested" => Dict(
        "n1"=>1,
        "n2"=>2,
    ),  
    "leaf2" => 2,
    "leaf" => 2,
    "leafme" => "v",
    "canopy" => "test",
)


tree_dict_3 = Dict(
    "nested" => Dict(
        "deeper"=>Dict(
            "aleaf"=>"unbeliefable",
            "leaflet"=>"level 3"
        ),
        "n2"=>Int,
        "n3"=>1 + 2,
    ),  
    "nested2" => Dict(
        "n1"=>"a",
        "n2"=>2,
    ),  
)


tree_dict_4 = Dict(
    "nested" => Dict(
        "deeper"=>Dict(
            "aleaf"=>"unbeliefable",
            "leaflet"=>"level 3",
            "sodeep" => Dict(
                "a"=>4
            )
        ),
        "n2"=>Int,
        "n3"=>1 + 2,
        "adict"=>Dict(
            "x"=>2
        )
    ),  
    "nested2" => Dict(
        "n1"=>"a",
        "n2"=>2,
    ),  
)



@testset "\e[34mTree" begin
    testpanel(
        Tree(tree_dict), 28, 6
    )


    testpanel(
        Tree(tree_dict_1), 15, 9
    )

    testpanel(
        Tree(tree_dict_2), 18, 11
    )

    testpanel(
        Tree(tree_dict_3), 33, 13
    )

    testpanel(
        Tree(tree_dict_4), 33, 19
    )
end