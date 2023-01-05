using Term
using Term.LiveDisplays
using Term.Consoles
using Term.Progress

# clear() 

# inspect(Panel)

mn = MultiSelectMenu(["One ",  "two", "three"])
retval = mn |> LiveDisplays.play
return retval