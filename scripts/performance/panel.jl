import Term: Panel, RenderableText


println("Panel no content")
@time Panel()
@time Panel(; fit=true)
@time Panel(; width=22, height=5)


println("short text panels")
txt = "This is my first panel!"
@time Panel(txt)
@time Panel(txt; justify=:right)
@time Panel(txt; fit=true)

println("long text panels")
txt = ","^500
@time Panel(txt)
@time Panel(txt; justify=:right)
@time Panel(txt; fit=true)

println("nested panels")
p1 = Panel(; width=10, height=5, style="red")
@time Panel(p1)
@time Panel(p1; fit=true)

# TODO visually inspect panel with different texts/renderables/padding combinations
# TODO improve Panel docstring and functions order