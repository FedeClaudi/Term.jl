using Term.LiveDisplays

"""
Simple interactive menu. 

Use arrows to navigate, "Enter" to confirm an opton and "q" to exit. "h" prints a help message.
"""

println("Please choose a menu type:")
retval = SimpleMenu(["Simple", "Buttons", "MultiSelect"]) |> LiveDisplays.play
print("\n\n")

# get the selected menu style
mn = if retval == 1
    println("\n This is an example of a SimpleMenu")
    SimpleMenu(["One", "Two", "Three"]; active_style="white bold",inactive_style="dim",)
elseif retval == 2
    println("\n This is an example of a ButtonsMenu")
    ButtonsMenu(["One", "Two", "Three"]; width=20)
elseif retval == 3
    println("\n This is an example of a MultiSelectMenu")
    MultiSelectMenu(["One ",  "two", "three"])
end

println("\nPlease choose an option:")
retval = mn |> LiveDisplays.play

print("The menu returned the value: $retval")


# TODO make text appear