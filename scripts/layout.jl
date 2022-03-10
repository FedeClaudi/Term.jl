using Term

p1 = Panel(; width = 5, height = 5)
p2 = Panel(; width = 8, height = 4)

print(p1 / p2)
p1 / p2

# @test (p1 * p2).measure.w == 13
# @test (p1 * p2).measure.h == 5

r1 = RenderableText("."^100; width = 25)
r2 = RenderableText("."^100; width = 50)

r = r1 / r2