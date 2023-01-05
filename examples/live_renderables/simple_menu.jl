using Term.LiveDisplays

"""
Simple interactive menu. 

Use arrows to navigate, "Enter" to confirm an opton and "q" to exit. "h" prints a help message.
"""

mn = SimpleMenu(["One", "Two", "Three"]; active_style="white bold",inactive_style="dim",)

println("Please choose an option:")
retval = mn |> LiveDisplays.play

print("The menu returned the value: $retval")


# TODO make text appear