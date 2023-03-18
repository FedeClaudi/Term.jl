# [Tree](@id TreeDoc)

The `Tree` renderable shows hierarchical structures:

```@example tree
import Term.Trees: Tree

data = Dict(
    "a" => 1,
    "b" => Int64,
    "c" => (1, 2, 3),
)

print(Tree(data))
```

As you can see, the starting point is a `Dict` with `key -> value` entries which get rendered as leaves in the tree. Also, the `Type` of `value` is shown by colors in the tree.

If you have nested data, just create nested dictionaries!

```@example tree
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

Under the hood, `Tree` just leverages [AbstractTrees.jl](https://github.com/JuliaCollections/AbstractTrees.jl) to handle tree-like data structures, so anything that is compatible with that framework will printed as a `Tree`.


```@example tree
# expressions
Tree(:(print, (:x, :(y+1)))) |> print

# arrays
Tree([1, [1, 2, [:a, :b, :c]]]) |> print

# and more!
```

Essentially `Tree` work's with `AbstractTrees` to just produce stylized output. 

!!! tip `Tree` is not a *tree*
    `Tree` is an `AbstractRenderable`, it is **not** a datastructure for handling tree-like data. It's only meant to be used to *display* trees in your terminal. As such you can't do operations like finding children of nodes or getting a subtree etc. All of that should be done with `AbstractTrees` and `Tree` is only there to display the output


As per the note above, `Tree` is a `AbstractRenderable` type so it plays well with other renderables in term. 

```@example tree
import Term: Panel

data = Dict(
    "a" => 1,
    "b" => Int64,
    "c" => (1, 2, 3),
)

_tree = Tree(data)
_info = Panel("This is a panel\nYou can use it to explain\nwhat the contents of the\ntree are!"; width=30, height=_tree.measure.h, subtitle="description")

print(_tree * "  " *_info)

```

### Styling
Easy! [`Tree`](@ref) has lots of options to allow you to style it as you like.
The style is set by the [`Theme`](@ref ThemeDocs). 

```@example tree
import Term: Theme
using MyterialColors

# create a new theme editing the tree style
theme = Theme(
    tree_mid             = blue,
    tree_terminator       = blue,
    tree_skip           = blue,
    tree_dash           = blue,
    tree_trunc         = blue,
    tree_pair           = red_light,
    tree_keys           = yellow,
    tree_max_leaf_width = 22,
)

print(
    Tree(data,
        theme=theme
    )
)
```
`tree_max_leaf_width` sets the max width of the display of each leaf while the other values set the color of different elements of the `Tree`. In particular `mid`, `terminator`, `dash` refer to the lines (or guides) of the tree. 

And since we're talking about `guides` you can also use different ones
```@example tree
print(
    Tree(data,
        guides=:asciitree
    )
)
```

there's a couple named guides style, but you can customize things even further using an `AbstractTree.TreeCharSet` if you wish.


## TypeTree
As you know, Julia allows for hierarchical types structures. Trees are for visualizing hierarchical data structures. So...

```@example
import Term: typestree

typestree(AbstractFloat)
```

Enjoy!