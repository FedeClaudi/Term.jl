"""
    This example shows how to use Term's layout functionality.


When creating structured terminal output, you want to have control
over what goes well. Maybe you want to print two panels, side by side, 
or you want to stack them vertically. Maybe you want to have some space
between content or use line to delimit sections of content that should be
separate. Term.jl has got your back.
"""

"""
Let's start with stacking. 
You can use `*` to horizontally stack content, and `/` to stack it
vertically.
"""

using Term
using Term.Layout

# with strings
s1 = @red "one string"
s2 = @green "and another"

println(s1 * " " * s2)
println(s1 / s2)

# with panels (and text boxes)
p1 = Panel("content {blue}content{/blue} "^10; fit = false, width = 30)
tb1 = TextBox("this is a text box! "^5; width = 66)

println(p1 * tb1)
println(p1 / tb1)

# you can stack multiple things too, and mix types
println(s1 / p1 / s2 / tb1)

"""
Now, stacking things is great, but want if you want some space between them?
`Spacer` lets you create an empty space with set width and height
"""
space = Spacer(p1.measure.h, 20)  # create empty space with same height as p1!

# horizontally stack everything and print!
top = p1 * space * p1
println(top)

"""
you can use `hLine` and `vLine` to create styled lines to separate pieces of content
"""

print("\n\n\n")
vline = vLine(p1.measure.h; style = "blue")  # create a vertical line as high as the panel
top = p1 * vline * space * vline * p1
line = hLine(top.measure.w, "some space"; style = "red", box = :DOUBLE)

# vertically stack everything and print nested in a panel
println(
    Panel(
        top / line / top;
        title = "layout is great!",
        title_style = "bold red",
        style = "red dim",
        title_justify = :left,
        fit = true,
    ),
)
