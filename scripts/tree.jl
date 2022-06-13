import Term.Trees: Tree
import Term: hLine, vLine

function pprint(tree::Tree)
    print(" " * hLine(tree.measure.w; style = "red"))
    print(vLine(tree.measure.h; style = "red") * tree)
    return println(tree.measure)
end

tree_dict = Dict(
    "nested\nasdasdsada\nsdasdsad\nsadasdasdasd\nsadasasdasdas\nsfsdfdsfds\nfdsfsdfsdf\ndsfsdfd" =>
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

print("\n"^20)

for dd in (tree_dict, tree_dict_1, tree_dict_2, tree_dict_3, tree_dict_4)
    pprint(Tree(dd))
    print("\n")
end
