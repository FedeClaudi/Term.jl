module Consoles
import Term: ACTIVE_CONSOLE_WIDTH, ACTIVE_CONSOLE_HEIGHT
export console_height,
    console_width,
    cursor_position,
    up,
    beginning_previous_line,
    prev_line,
    next_line,
    down,
    clear,
    hide_cursor,
    show_cursor,
    line,
    erase_line,
    cleartoend,
    move_to_line,
    change_scroll_region,
    savecursor,
    restorecursor,
    Console,
    enable,
    disable

const STDOUT = stdout
const STDERR = stderr

# ---------------------------------------------------------------------------- #
#                                CURSOR CONTROL                                #
# ---------------------------------------------------------------------------- #
"""
Save the current cursor position
"""
savecursor(io::IO = stdout) = write(io, "\e[s")

"""
Restore a previously saved cursor position
"""
restorecursor(io::IO = stdout) = write(io, "\e[u")

"""
Get cursor position
"""
cursor_position(io::IO = stdout) = write(io, "\e[6n")

# --------------------------------- movement --------------------------------- #

"""
Move cursor to the beginning of the previous line
"""
beginning_previous_line(io::IO = stdout) = write(io, "\e[F")

"""
Move cursor up one one or more lines
"""

prev_line(io::IO = stdout, n::Int = 1) = write(io, "\e[" * string(n) * "F")

up(io::IO = stdout, n::Int = 1) = write(io, "\e[" * string(n) * "A")

"""
Move cursor down one or more lines
"""
next_line(io::IO = stdout, n::Int = 1) = write(io, "\e[" * string(n) * "E")

down(io::IO = stdout, n::Int = 1) = write(io, "\e[" * string(n) * "B")

"""
Move cursor to a specific line
"""
move_to_line(io::IO = stdout, n::Int = 1) = write(io, "\e[" * string(n) * ";1H")

# ---------------------------------- display --------------------------------- #
"""
    clear(io::IO = stdout)

Clear terminal from anything printed in the REPL.
"""
clear(io::IO = stdout) = write(io, "\e[2J")
cleartoend(io::IO = stdout) = write(io, "\e[0J")

"""
Hide cursor
"""
hide_cursor(io::IO = stdout) = write(io, "\e[?25l")

"""
Show cursor
"""
show_cursor(io::IO = stdout) = write(io, "\e[?25h")

"""
write a new line.
"""
line(io::IO = stdout, i = 1) = write(io, "\n"^i)

"""
Erase last line in console.
"""
erase_line(io::IO = stdout) = write(io, "\e[2K")

"""
Change the position of the scrolling region in the terminal.

See: http://www.sweger.com/ansiplus/EscSeqScroll.html
"""
function change_scroll_region(io::IO = stdout, n::Int = 1)
    write(io, "\e[1;" * string(n) * "r")  # from row 1 to n, all columns
    return down(io, n)
end

# ---------------------------------------------------------------------------- #
#                                    CONSOLE                                   #
# ---------------------------------------------------------------------------- #
"""
    console_height()

Get the current console height.
"""
console_height(io::IO = stdout) = something(ACTIVE_CONSOLE_HEIGHT[], displaysize(io)[1])

"""
    console_width()

Get the current console width.
"""
console_width(io::IO = stdout) = something(ACTIVE_CONSOLE_WIDTH[], displaysize(io)[2])

mutable struct Console
    height
    width
end

Console(width) = Console(console_height(), width)
Console() = Console(console_height(), console_width())
Base.displaysize(c::Console) = (c.height, c.width)

function enable(console::Console)
    ACTIVE_CONSOLE_WIDTH[] = console.width
    console
end

function disable(console::Console)
    ACTIVE_CONSOLE_WIDTH[] = nothing
    console
end
end
