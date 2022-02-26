using Revise
Revise.revise()

import Term.markup: extract_markup

using Term

# -------------------------------- nested tags ------------------------------- #
# println(RenderableText(
#     "You [green]can nest [blue underline] one [on_gold3 black bold]style[/on_gold3 black bold] inside  [/blue underline] another too!"

# ))


# ------------------------------ text reshaping ------------------------------ #
text = "This is a [blue][gold3]very[/gold3] long[/blue] piece of [green]text with [red]nested[/red] styles[/green]!! "^6

for width in [9, 29, 37, 50]
    print("\n\n")
    println("Width: $width")
    println("."^width)

    print(RenderableText(text; width=width))
end