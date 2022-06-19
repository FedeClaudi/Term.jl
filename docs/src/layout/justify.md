# Justify

We've seen that you can vertically stack renderables:

```@example justify
using Term
using Term.Layout

p1 = Panel(height=3, width=20)
p2 = Panel(height=3, width=40)
p3 = Panel(height=3, width=60)
vstack(p1, p2, p3;)
```

but when the renderables have unequal lengths they all get pushed to the left. This might not be what you want, so you can use the `justify` function to align them:
```@example justify

center!(p1, p2, p3;)  # there's also the non-modifying `center
vstack(p1, p2, p3;)
```

calling `center!(p1, p3;)` modifies the two renderables to ensure that they have the same width by padding to the left and right so that they're centered. You can also use `rightalign!` and `leftalign!` to align them to the right or left respectively too.

Admittedly, this is nice but the syntax is a bit clunky. But don't worry of course we provide a shorthand notation to stack and justify in one fell swoop (because why would you justify if you're not stacking):

```@example justify
p1 = Panel(height=3, width=20)
p2 = Panel(height=3, width=40)
p3 = Panel(height=3, width=60)

rvstack(p1, p2, p3;)
```

`rvstack` justifies to the right and vertically stacks renderables. Guess what `cvstack` and `lvstack` do?