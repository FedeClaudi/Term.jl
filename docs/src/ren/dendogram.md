# [Dendogram](@id DendoDoc)

Similarly to [Tree](@ref TreeDoc), `Dendogram` is a renderable that can be used to visualize hierarchical data:

```@example dendo
import Term.Dendograms: Dendogram

dendo = Dendogram("trunk", "the", "tree", "has", "leaves")
print(dendo)
```

As you can see, the first argument is the "trunk" or title of the dendogram while all other arguments are added as leaves. Compare it to a `Tree` renderable:

```@example
import Term: Tree
print(
    Tree(
        Dict(:a=>"the", :b=>"tree", :c=>"has", :d=>"leaves")
    )
)
```

If you've seen [Tree](@ref TreeDoc), you'll know that `Tree` can handle nested hierarchical structures, what about `Dendogram`? The way you do that is by `linking` individual dendograms:

```@example dendo
import Term.Dendograms: link

mydend = Dendogram("first", [1, 2])
otherdend = Dendogram("other", [:a, :b])

print(
    link(mydend, link(otherdend, otherdend; title="another level"); title="One level")
)
```

