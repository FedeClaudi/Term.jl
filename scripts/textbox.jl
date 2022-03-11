using Term

prt(tb) = print(tb, tb.measure, "\n")

# prt(TextBox(
#     "nofit"
# ))

print("\n"^20)

# check that unreasonable widhts are ignored
prt(TextBox(
    "nofit"^25;
    width=1000
))

prt(TextBox(
    "truncate"^25;
    width=100,
    fit=:truncate
))

prt(TextBox(
    "truncate"^25;
    width=100,
))

prt(TextBox(
    "truncate"^8;
    fit=:fit
))

prt(TextBox(
    "[red]truncate[/red]"^8;
    fit=:fit
))

prt(TextBox(
    "[red]tru\nncate[/red]test"^1;
    fit=:fit
))