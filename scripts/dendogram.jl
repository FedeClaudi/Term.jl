import Term: Dendogram, Panel, Tree, inspect, theme, expressiontree
using Term.dendogram

# -------------------------------- playground -------------------------------- #
# WORKS
# e = :(2x + 3y + 2)
# e = :(2x + 3y + 2z)
# e = :(2x + 3 + 2 + 2y)
# e = :(2x^(3+y))
# e = :(x^(3+y))
# e = :(1 + 1 - 2x^2)
# e = :(mod(22, 6))
# e = :(2x^(3+y) + 2z)
# e = :(mod(x, 2) + sum(map(y->2y, 1:10)))
# e = :(2x + 3 * √(3x^2))
# e = :(print(x))
# e = :(print(lstrip("test")))

# NOWORKS
# e = :(for i in 1:10; println(i); end) 

e = :(2x + 3y + 2z^2)

theme.tree_max_width = 100

print("\n"^3)
expressiontree(e)
inspect(e)

# TODO make Tree work for vector of Pair/Dict
