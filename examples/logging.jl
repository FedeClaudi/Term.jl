"""
    This example shows how to use Term's styled logging

It's as simple as calling one function, Term takes care of the rest
so you can use Julia's logging functionality as you would normally
"""

import Term: install_term_logger, uninstall_term_logger, Panel

# install term's logger as the global logger
install_term_logger()

# log
@info "my log!"

"""
as you can see the output is similar to the default logging system, with just
a couple more details. However you can now add markdown style to your
log messages
"""

@warn "tell us if this was {bold red}undexpected!{/bold red}"

"""
but there's more!
Just like in the normal logging system you can pass additional arguments to the logging macro.
Term's logger prints them with additional information, and some style of course.
"""

x = collect(1:2:20)
y = x * x'
name = "the name is {bold blue}Term{/bold blue}"
p1 = Panel("text")

print('\n'^3)
@error "{italic green bold}fancy logs!{/italic green bold}" x y name √9 install_term_logger p1

"""
You can reset Julia's default logger like this:
"""

uninstall_term_logger()
@error "{italic green bold}fancy logs!{/italic green bold}" x y name √9 install_term_logger p1
