using Term
import Term: chars

prt(pan) = begin
    print(" " * hLine(pan.measure.w; style="red"))
    print(vLine(pan.measure.h; style="red") * pan)
    println(pan.measure, "   ", length(pan.segments) )
end


print("\n"^5)


# check that unreasonable widhts are ignored
@time prt(TextBox(
    "nofit"^25;
    width=1000
))

@time prt(TextBox(
    "truncate"^25;
    width=100,
    fit=:truncate
))

@time prt(TextBox(
    "truncate"^25;
    width=100,
))

@time prt(TextBox(
    "truncate"^8;
    fit=:fit
))

@time prt(TextBox(
    "[red]truncate[/red]"^8;
    fit=:fit
))

@time prt(TextBox(
    "[red]tru\nncate[/red]test"^1;
    fit=:fit
))


@time prt(
    TextBox(
    "[red]truncate[/red]test"^8;
    fit=:fit,
    justify=:left
)
)