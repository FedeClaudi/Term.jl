using Term.LiveWidgets

println("Please choose a menu type:")
retval =
    App(SimpleMenu(["Simple", "Buttons", "MultiSelect"]); height = 3) |> LiveWidgets.play
print("\n\n")

# get the selected menu style
mn = if retval == 1
    println("\n This is an example of a SimpleMenu")
    SimpleMenu(["One", "Two", "Three"]; active_style = "white bold", inactive_style = "dim")
elseif retval == 2
    println("\n This is an example of a ButtonsMenu")
    ButtonsMenu(
        ["One", "Two", "Three"];
        active_background = ["green", "white", "red"],
        active_color = "bold black",
        inactive_color = ["green", "white", "red"],
        layout = :horizontal,
    )
elseif retval == 3
    println("\n This is an example of a MultiSelectMenu")
    MultiSelectMenu(["One ", "two", "three"])
end

println("\nPlease choose an option:")
retval = LiveWidgets.play(App(mn; height = mn.internals.measure.h); transient = false)

print("The menu returned the value: $retval")
