using Term
import Term: Renderable

pprint(x) = begin
    println(x)
    println(x.measure)
end

p1 = Panel()
p2 = Panel(; width=24, height=3)
p3 = Panel("test[red]aajjaja[/red]"^5, width=12)

# pprint(p1 * p2)
# pprint(p1 / p2)

a = p1 / p2
