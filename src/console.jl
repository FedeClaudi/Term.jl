module consoles

export Console, console, err_console, console_height, console_width

const STDOUT = stdout
const STDERR = stderr

# --------------------------------- controls --------------------------------- #

"""
Get cursor position
"""
cursor_position() = print("\e[6n")
cursor_position(io::IO) = print(io, "\e[6n")

"""
Move cursor up one line
"""
up() = print("\e[A") 
up(io::IO) = print(io, "\e[A") 

"""
Move cursor to the beginning of the previous line
"""
beginning_previous_line() = print("\e[F")
beginning_previous_line(io::IO) = print(io, "\e[F")

"""
Move cursor down one line
"""
down() = print("\e[B")
down(io::IO) = print(io, "\e[B")

"""
Clear terminal.
"""
clear() = print("\x1b[2J")
clear(io::IO) = print(io, "\x1b[2J")

"""
Hide cursor
"""
hide_cursor() = print("\x1b[?25l")
hide_cursor(io::IO) = print(io, "\x1b[?25l")


"""
Show cursor
"""
show_cursor() = print("\x1b[?25h")
show_cursor(io::IO) = print(io, "\x1b[?25h")

"""
Print a new line.
"""
line(; i=1) = print("\n"^i)
line(io::IO; i=1) = print(io, "\n"^i)


"""
Erase last line in console.
"""
erase_line() = print("\e[2K\r")
erase_line(io::IO) = print(io, "\e[2K\r")


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
