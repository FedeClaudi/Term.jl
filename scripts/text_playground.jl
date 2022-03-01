using Revise
Revise.revise()

using Term
import Term: install_stacktrace

install_stacktrace()
# -------------------------------- nested tags ------------------------------- #
println(RenderableText(
    "You [green]can nest [blue underline] one [on_gold3 black bold]style[/on_gold3 black bold] inside  [/blue underline] another [/green]too!"

))


# ----------------------------- >2 tags per line ----------------------------- #
println(
    RenderableText(
        "[red]reeed [blue]blueeee[/blue] reeeed [green] greeen [/green] red red red[/red]"
    )
)


# ------------------------------ text reshaping ------------------------------ #
text = "This is a [blue][gold3]very[/gold3] long[/blue] piece of [green]text with [red]nested[/red] styles[/green]!! "^6

for width in [9, 29, 37, 50]
    print("\n\n")
    println("Width: $width")
    println("."^width)

    print(RenderableText(text; width=width))
end


text = "[red]TEST[/red]aaa"^20
# text = "TESTaaa"^10

for width in [21, 44, 81]
    print("\n\n")
    println("Width: $width")
    println("."^width)

    print(RenderableText(text; width=width))
end
