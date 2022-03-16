using Term


prt(pan) = begin
    print(" " * hLine(pan.measure.w; style="red"))
    print(vLine(pan.measure.h; style="red") * pan)
    println(pan.measure, "   ", length(chars(pan.segments[1].plain)), "  ", length(pan.segments) )
end





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


prt(
    TextBox(
    "[red]truncate[/red]test"^8;
    fit=:fit,
    justify=:left
)
)