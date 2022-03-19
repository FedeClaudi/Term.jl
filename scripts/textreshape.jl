import Term: reshape_text, Panel

lorem1 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
lorem2 = """Lorem ipsum dolor sit amet, consectetur adipiscing elit, 
sed do eiusmod tempor incididunt ut labore et dolore
 magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation 
 ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute 
 irure dolor in reprehenderit in voluptate velit esse cillum dolore 
 eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, 
 sunt in culpa qui officia deserunt mollit anim id est laborum."""

# for lorem in (lorem1, lorem2), width in (10, 24, 37)
    # println("."^width)
    # println(reshape_text(lorem, width))
    # println("."^width)

    # @time reshape_text(lorem, width)
# end

styled = "text [red] red red redredred [/red] and [bold blue] bold blue is blue and bold[green] this is actually green[/green] still bold blue[/bold blue] this is normal"
for width in (10, 24, 37)
    println("."^width)
    @time println(reshape_text(styled, width))
    println("."^width)

    # break
end
