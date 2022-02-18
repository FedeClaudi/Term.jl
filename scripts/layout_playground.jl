import Term: hLine, vLine, Spacer, vstack, hstack


mid = vstack(
    Spacer(20,  5),
    hLine(20, "red"),
    Spacer(20, 5)
)

full = hstack(
    vLine(10, "red"; box=:HEAVY),
    mid,
    vLine(10, "red"; box=:HEAVY),
)

print(full)
