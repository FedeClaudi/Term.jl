module consoles

export Console, console, err_console, console_height, console_width


# --------------------------------- controls --------------------------------- #
"""
Clear terminal.
"""
clear() = print("\x1b[2J")

"""
Hide cursor
"""
hide_cursor() = print("\x1b[?25l")


"""
Show cursor
"""
show_cursor() = print("\x1b[?25h")

"""
Print a new line.
"""
line() = print("\n")

"""
Erase last line in console.
"""
erase_line() = print("\e[2K\r")


# ---------------------------------------------------------------------------- #
#                                    CONSOLE                                   #
# ---------------------------------------------------------------------------- #
"""
    Console

The `Console` object stores information about the dimensions of the output(::IO)
where objects will be printed
"""
struct Console
    io::IO
    width::Int
    height::Int
end

Console(io::IO) = Console(io, displaysize(io)[2], displaysize(io)[1])
Console() = Console(stdout)

console = Console(stdout)
err_console = Console(stderr)

"""
    console_height()

Get the current console height.
"""
console_height() = displaysize(stdout)[1]
console_height(io::IO) = displaysize(io)[1]

"""
    console_width()

Get the current console width.
"""
console_width() = displaysize(stdout)[2]
console_width(io::IO) = displaysize(io)[2]

end
