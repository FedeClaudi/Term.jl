ANSI_OPEN_REGEX = r"\e\[0m"
ANSI_CLOSE_REGEX = r"\e\[[0-9]+\;[0-9]+\;[0-9]+[m]"

"""
Removes all ANSI tags
"""
strip_ansi(str::String) = replace(replace(str, ANSI_OPEN_REGEX => ""), ANSI_CLOSE_REGEX => "")


ansi = "3\e[0;37;44m---\e[0mwhite on_blue] [green]Test[/green] --- [black on_green]success![/black on_green]?"


print(strip_ansi(ansi))