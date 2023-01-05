using Term
using Term.LiveDisplays
using Term.Consoles
using Term.Progress

clear()

# inspect(Panel)

mn = ButtonMenu(["One "^50, "{red}Two{/red}", Panel("Three"; fit=true)])
retval = mn |> LiveDisplays.play
return retval