module consoles

    export Console, console, err_console
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

end