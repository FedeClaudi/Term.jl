"""
    This example shows how to create Dendogram visualizations.


According to wikipedia: "A dendrogram is a diagram representing a tree", 
but really you just need to see to understand:
"""

import Term: Dendogram

mydendo = Dendogram("awesome", "this", :is, "a", "dendogram!")
print("\n"^2)
print(mydendo)

"""
The first argument si the "head" (or trunk) and all the others are leaves
"""

otherdendo = Dendogram("head", "these", "are", "colorful", "leaves")
print("\n"^2)
print(otherdendo)

"""
Let's say you want to create a hierarchical structure in your dendogram, 
just link individual elements together.
"""

import Term.Dendograms: link
print("\n"^2)
print(link(mydendo, otherdendo; title = "{red}superdendo{/red}"))

"""
and so on...
"""
smalldendo = Dendogram("head", [1, 2])

print("\n"^2)
print(
    link(
        smalldendo,
        link(
            smalldendo,
            link(smalldendo, smalldendo; title = "a level");
            title = "another level",
        );
        title = "first level",
    ),
)
