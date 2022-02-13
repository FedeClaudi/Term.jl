import Term

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