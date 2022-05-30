import Term.Renderables: Renderable, RenderableText

lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

println("Renderable text no style")
@time RenderableText(lorem)
@time RenderableText(lorem; width = 22)

println("Renderable text with style")
@time RenderableText(lorem; style = "red")
@time RenderableText(lorem; width = 22, style = "blue")

println("Re-create RT")
rt = RenderableText(lorem; style = "red")
@time RenderableText(rt; style = "red", width = rt.measure.w)
@time RenderableText(rt; style = "blue", width = rt.measure.w)

print("renderable of renderable")
ren = RenderableText(lorem; style = "red")
@time Renderable(ren);
