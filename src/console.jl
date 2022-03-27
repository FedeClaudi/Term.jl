module consoles

export Console, console, err_console, console_height, console_width

const STDOUT = stdout
const STDERR = stderr

# --------------------------------- controls --------------------------------- #

"""
Get cursor position
"""
cursor_position() = cursor_position(stdout)
cursor_position(io::IO) = print(io, "\e[6n")

"""
Move cursor up one line
"""
up() = up(stdout)
up(io::IO) = print(io, "\e[A") 

"""
Move cursor to the beginning of the previous line
"""
beginning_previous_line() = beginning_previous_line(stdout)
beginning_previous_line(io::IO) = print(io, "\e[F")


prev_line(; n::String="1") = prev_line(stdout; n=n)
prev_line(io::IO; n::String="1") = print(io, "\e["*n*"F")

next_line(; n::String="1") = next_line(stdout; n=n)
next_line(io::IO; n::String="1") = print(io, "\e["*n*"E")

"""
Move cursor down one line
"""
down() = down(stdout)
down(io::IO) = print(io, "\e[B")

"""
Clear terminal.
"""
clear() = clear(stdout)
clear(io::IO) = print(io, "\x1b[2J")

"""
Hide cursor
"""
hide_cursor() = hide_cursor(stdout)
hide_cursor(io::IO) = print(io, "\x1b[?25l")


"""
Show cursor
"""
show_cursor() = show_cursor(stdout)
show_cursor(io::IO) = print(io, "\x1b[?25h")

"""
Print a new line.
"""
line(; i=1) = line(stdout; i=i)
line(io::IO; i=1) = print(io, "\n"^i)


"""
Erase last line in console.
"""
erase_line() = erase_line(stdout)
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
