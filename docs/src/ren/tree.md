# [Tree](@id TreeDoc)

The `Tree` renderable shows hierarchical structures:

```@example
import Term.tree: Tree

data = Dict(
    "a" => 1,
    "b" => Int64,
    "c" => (1, 2, 3),
)

print(Tree(data))
```

As you can see, the starting point is a `Dict` with `key -> value` entries which get rendered as leaves in the tree. Also, the `Type` of `value` is shown by colors in the tree.

If you have nested data, just create nested dictionaries!

```@example
import Term.tree: Tree

data = Dict(
    "a" => 1,
    "b" => Int64,
    "deep" => Dict(
            "x" => 1,
            "y" => :x
    ),
)

print(Tree(data))
```

Easy! [`Tree](@ref) has lots of options to allow you to style it as you like:

```@example
import Term.tree: Tree # hide

data = Dict( # hide
    "a" => 1, # hide
    "b" => Int64, # hide
    "deep" => Dict( # hide
            "x" => 1, # hide
            "y" => :x # hide
    ), # hide
) # hide

print(
    Tree(data,
        title="my custom tree",
        title_style="red",
        guides_style="green",
        guides_type=:boldtree
    
    )
)
```

And of course trees behave just like any renderable so you can create layouts with them:
```@example
data = Dict(
    "a" => 1,
    "b" => Int64,
    "deep" => Dict(
            "x" => 1,
            "y" => :x
    ),
)

tree = Tree(data)

print(
    ("\n" / tree) * "  " * Panel(tree;fit=true)
)
```

## TypeTree
As you know, Julia allows for hierarchical types structures. Trees are for visualizing hierarchical data structures. So...

```@exaple
import Term: typestree

typestree(AbstractFloat)
```

Enjoy!