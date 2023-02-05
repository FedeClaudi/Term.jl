"""
This example shows how to create Tree visualizations.


The easiest starting point is a `Dict` object with the info we want
to show in the tree
"""

import Term: Tree, Theme

data = Dict("a" => 1, "b" => Int64, "c" => [1, 2, 3], "d" => "a b c"^100)

print(Tree(data))

"""
`Tree` has several parameters that can be used to change the appearance
"""

print("\n\n")
for guides in (:standardtree, :boldtree, :asciitree)
    Tree(data; guides = guides) |> print
end

# set the colors!
print("\n\n")
theme = Theme(
    tree_mid = "green",
    tree_terminator = "green",
    tree_skip = "green",
    tree_dash = "green",
    tree_trunc = "green",
    tree_pair = "red",
    tree_keys = "blue",
    tree_max_leaf_width = 44,
)
print(Tree(data; theme = theme))

"""
Tree can handle nested data too!
"""
data = Dict(
    "lvl1" => Dict(
        "lvl2" => Dict("a" => 1, "b" => 3),
        "l2a" => "nested dicts rule!",
        "l2b" => "wohoo",
    ),
)

print(Tree(data))
