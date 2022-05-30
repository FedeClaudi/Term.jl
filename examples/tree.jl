"""
This example shows how to create Tree visualizations.


The easiest starting point is a `Dict` object with the info we want
to show in the tree
"""

import Term: Tree

data = Dict(
    "a" => 1,
    "b" => Int64,
    "c" => [1, 2, 3],
)

print(Tree(data))

"""
`Tree` has several parameters that can be used to change the appearance
"""

print("\n\n")
for guides_type in (:standardtree, :boldtree, :asciitree)
    print(Tree(data; title=string(guides_type), guides_type=guides_type))
end

# set the colors!
print("\n\n")
print(
    Tree(
        data,
        title="my colors",
        title_style="bold red",
        node_style="blue underline",
        leaf_style="green",
        guides_style="red dim"
    )
)


"""
Tree can handle nested data too!
"""
data = Dict(
    "lvl1" => Dict(
        "lvl2" => Dict(
            "a" => 1,
            "b" => 3,
        ),
        "l2a" => "nested dicts rule!",
        "l2b" => "wohoo"
    )
)

print(Tree(data))