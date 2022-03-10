using Term

prt(tb) = print(tb, "\n", tb.measure, "\n")

# prt(TextBox(
#     "nofit"
# ))

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
))ork

prt(TextBox(
    "truncate"^25;
    fit=:fit
))