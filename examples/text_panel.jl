"""
    This example shows how to use panels in Term.jl

A `Panel` prints a piece of content surrounded by a border.
It's one of the best and easiest way to style your terminal output,
especially if you nest multiple panels or use Term's layout functionality
to create a structured terminal output.
"""

import Term: Panel

# Creating a panel is very simple

print(Panel("This is my first panel!"))

"""
By default Panel expands to fit its content. 
You can use different options to change this behavior.
"""

print("\n\n")
print(
    Panel("this panel has fixed width, text on the left"; width = 66, justify = :left),
    Panel("this one too, but the text is at the center!"; width = 66, justify = :center),
    Panel("the text is here!"; width = 66, justify = :right),
    Panel("this one fits its content"; fit = true),
    Panel("this one fits the terminal window size!"; width = 30),
)

"""
As you can see you can also specify how the panel's content should be justified. 
Of course you can use markup styled text in your panel.
"""

print("\n\n")
print(
    Panel(
        "{red}This is the panel's first line.{/red}",
        "{bold green}and this is another, panel just stacks all inputs into one piece of content{/bold green}";
        fit = true,
    ),
)

"""
When it comes to style, panel offers a lot of options.
You can style the box itself and have titles and subtitles.
"""

print("\n\n")

print(
    Panel("content "^10; title = "My Panel", title_style = "bold red", width = 44),
    Panel(
        "content "^10;
        subtitle = "another panel",
        subtitle_style = "dim underline",
        subtitle_justify = :right,
        width = 44,
    ),
    Panel("content "^10; box = :ASCII_DOUBLE_HEAD, style = "red", width = 44),
    Panel("content "^10; box = :DOUBLE, style = "blue", width = 44),
    Panel("content "^10; fit = true, padding = (0, 0, 0, 0)),
    Panel("content "^10; fit = true, padding = (4, 4, 0, 0)),
    Panel("content "^10; fit = true, padding = (2, 2, 2, 2)),
)

"""
Finally, you can layout panels to create structured content
"""

print("\n\n")
pleft = Panel("content "^30; box = :DOUBLE, style = "blue", width = 66)
pright = Panel(
    "content {red}with style{/red} "^26;
    title = "My Panel",
    title_style = "bold red",
    width = 44,
)

print(
    Panel(
        pleft / pright;
        style = "green dim",
        title_style = "green",
        title = "vertically stacked!",
        title_justify = :center,
        subtitle = "styled by Term.jl",
        subtitle_justify = :right,
        subtitle_style = "dim",
        justify = :center,
    ),
)
