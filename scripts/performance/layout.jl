import Term.Layout: pad, vLine, hLine
import Term: Panel

println("pad")
@time pad("aaa", 20, :left)
@time pad("aaa", 20, :right)
@time pad("aaa", 20, :center)

@time pad("aaa", 10, 20)
p = Panel(; width=20, height=10)
@time pad(p.segments, 10, 10);

println("string stacking")
s1 = "123"
s2 = "12345"

@time s1 * s2
@time s1 / s2

println("renderables stacking")
p2 = Panel(; width=5, height=12)
@time p * p2
@time p / p2

println("vLine")
@time vLine(10; style="red")
@time vLine(p2)

println("hLine")
@time hLine(10; style="red")
@time hLine(50, "title")

# TODO test hLine and vLine sizes correct