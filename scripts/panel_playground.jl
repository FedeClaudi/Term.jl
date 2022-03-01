import Term: Panel, RenderableText, TextBox
import Term: split_lines

# ----------------------------- basic and nested ----------------------------- #
# print(
#     Panel(
#         """
#         [green]This is a multiline text[/green]
#         [on_black]This line is [bold] different![/bold][/on_black]""",
#         subtitle="aa",
#         subtitle_justify=:right,
#         style="red",
#         title="From text",
#         width=44
#     )
# )
# println("."^44)
# print("\n\n")

w = 32
println(Panel(
    "."^w,
    title="TITLE",
    title_justify=:center,
    style="green",
    width=2w
))

# print(
#     Panel(
#         RenderableText("""
#         [green]This is a multiline text[/]
#         [on_black]This line is [bold]different!"""),
#         style="blue dim",
#         title="From Segment",
#         width=50,
#         justify=:center,
#         title_style="red bold"

#     )
# )
# println("."^50)
# print("\n\n")

# println(
#     Panel(
#         Panel("[bold white]Title panel!!", style="dim"),
#         Panel(RenderableText("""
#         [green]This is a multiline text[/]
#         [on_black]This line is [bold]different!
#         """),
#         style="blue dim",
#         title="From Segment",
#         # width=50,
#         justify=:center,
#         title_style="red bold",
#         subtitle="test",
#         subtitle_justify=:right,
#     ),
#     justify=:center, title="created with Term", title_style="gray62"
#     )
# )
# print("\n\n")

# ---------------------------------- textbox --------------------------------- #
# print(TextBox(
#     join("TEST"^4, "sdfs"^8, "\n"), title="test box!"
# ))
# print("\n\n")

# print(TextBox(
#     join("X"^26, "y"^8), title="test box!", title_style="bold red", width=44
# ))
# println("."^44)
# print("\n\n")


# ---------------------------- textbox with colors --------------------------- #

# print(TextBox(
#     "[red]TEST[/red]aaa"^10, title="test box!"; width=44
# ))
# println("."^44)
# print("\n\n")

# print(TextBox(
#     "[red]red [blue]blue[/blue][green]green[/green]red[/red]"^50, title="test box!", title_style="bold red", width=44
# ))
# println("."^44)
# print("\n\n")