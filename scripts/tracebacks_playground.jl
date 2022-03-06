using Revise

Revise.revise()

using Term

install_stacktrace()
import Base: ExceptionStack


import Term: highlight_syntax

# TODO mostly working but error not rendering correctly

# define nested functions
b(x::String) = x * "a"

"""
    This is a function!
"""
yet_another_function(z) = b(z)


# is this going to work?
outer(y) = yet_another_function(y)

# println(z)
1 = "a"

# outer(2)


# TODO load code and highlight https://juliadocs.github.io/Highlights.jl/stable/
# TODO try getting error hints again
