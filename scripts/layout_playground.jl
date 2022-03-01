import Term: hLine, vLine, Spacer, vstack, hstack


mid = vstack(
    Spacer(20,  5),
    hLine(20; style= "red"),
    Spacer(20, 5)
)

full = hstack(
    vLine(10; style="red", box=:HEAVY),
    mid,
    vLine(10; style="red", box=:HEAVY),
)

print(full)

println(
    hLine(140, "TITLE LINE"; style="green")
)
