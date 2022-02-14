import Revise
Revise.revise()

using Term

# ---------------------------------------------------------------------------- #
#                                   on string                                  #
# ---------------------------------------------------------------------------- #

@info "From string"
test = """
[black on_white]First line[/black on_white]
second line, both in the panel!"""

panel = Panel(test; style="green", width=40, justify=:left);
tprint(panel)


panel = Panel(test; style="white", width=40, justify=:center, box=:SQUARE);
tprint(panel)


panel = Panel(test; style="red", width=40, justify=:right);
tprint(panel)



# ---------------------------------------------------------------------------- #
#                                 on MarkupText                                #
# ---------------------------------------------------------------------------- #
@info "From MarkupText"
text = MarkupText(test)
tprint(Panel(text; box=:HEAVY))



# ---------------------------------------------------------------------------- #
#                                     title                                    #
# ---------------------------------------------------------------------------- #
print("\n"^4)
tprint(Panel("test tes wtagaegzdgdszfgg", title="m", box=:SQUARE))

tprint(Panel("test tes wtagaegzdgdszfgg", title="━━", box=:SQUARE))


tprint(Panel("test tes wtagaegzdgdszfgg", title="[red]Madasdasaseg56r6[/red]", box=:HEAVY))

tprint(Panel("test tes"^4, title="test"^3, box=:ASCII))


tprint(Panel("test tes"^12, title="Mega"^2, title_style="red", style="green"))


tprint(Panel("test tes"^6, title="Mega"^10))



# ---------------------------------------------------------------------------- #
#                                    NESTED                                    #
# ---------------------------------------------------------------------------- #

p1 = Panel("INSIDE\npanel")
tprint(Panel(
    p1; style="red", title="outer"
))