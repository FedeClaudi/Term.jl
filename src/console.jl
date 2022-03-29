module console

export console_height,
        console_width,
        cursor_position,
        up,
        beginning_previous_line,
        prev_line,
        next_line,
        down,
        clear,
        hide_cursor,show_cursor,line,
        erase_line,
        cleartoend,
        move_to_line,
        change_scroll_region

const STDOUT = stdout
const STDERR = stderr

# ---------------------------------------------------------------------------- #
#                                CURSOR CONTROL                                #
# ---------------------------------------------------------------------------- #
# --------------------------------- movement --------------------------------- #
"""
Get cursor position
"""
cursor_position(io::IO=stdout) = write(io, "\e[6n")


up(io::IO=stdout) = write(io, "\e[A") 

"""
Move cursor to the beginning of the previous line
"""
beginning_previous_line(io::IO=stdout) = write(io, "\e[F")


"""
Move cursor up one one or more lines
"""
prev_line(io::IO=stdout) = write(io, "\e[1F")
prev_line(io::IO=stdout, n::Int=1) = write(io, "\e["*string(n)*"F")

up(io::IO) = write(io, "\e[A")
up(io::IO, n::Int=1) = write(io, "\e["*string(n)*"A")


"""
Move cursor down one or more lines
"""
next_line(io::IO=stdout) = write(io, "\e[1E")
next_line(io::IO=stdout, n::Int=1) = write(io, "\e["*string(n)*"E")

down(io::IO) = write(io, "\e[B")
down(io::IO, n::Int=1) = write(io, "\e["*string(n)*"B")

move_to_line(io::IO=stdout, n::Int=1) = write(io, "\e["*string(n)*";1H")

# ---------------------------------- display --------------------------------- #
"""
Clear terminal.
"""
clear(io::IO=stdout) = write(io, "\e[2J")
cleartoend(io::IO=stdout) = write(io, "\e[0J")

"""
Hide cursor
"""
hide_cursor(io::IO=stdout) = write(io, "\e[?25l")

"""
Show cursor
"""
show_cursor(io::IO=stdout) = write(io, "\e[?25h")

"""
write a new line.
"""
line(io::IO=stdout, i=1) = write(io, "\n"^i)


"""
Erase last line in console.
"""
erase_line(io::IO=stdout) = write(io, "\e[2K")

"""
Change the position of the scrolling region in the terminal.
"""
function change_scroll_region(io::IO=stdout, n::Int=1)
    write(io, "\e[1;" * string(n) * "r")
    down(io, n)
end

# ---------------------------------------------------------------------------- #
#                                    CONSOLE                                   #
# ---------------------------------------------------------------------------- #
"""
    console_height()

Get the current console height.
"""
console_height(io::IO=stdout) = displaysize(io)[1]

"""
    console_width()

Get the current console width.
"""
console_width(io::IO=stdout) = displaysize(io)[2]

end
