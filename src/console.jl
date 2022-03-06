module consoles

    export Console, console, err_console, console_height, console_width
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

    console_height() = displaysize(stdout)[1]
    console_height(io::IO) = displaysize(io)[1]

    console_width() = displaysize(stdout)[2]
    console_width(io::IO) = displaysize(io)[2]

end