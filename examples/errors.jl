"""

    This example show's how to use Term's errors functionality


Term provides functionality to produce styled and informative error
messages and tracestacks. This is not active by default as not everybody
might want this, but it's easier to turn on.

NOTE: this is a preliminary feature, there might be bugs and not all error
types may be correctly represented. While generally useful, it might be best
to hold back on this feature for code that needs to reliably print acurate
error information.
"""

import Term: install_stacktrace
import Term: hLine

install_stacktrace()

print(hLine("Fancy Errors", style="bold blue"))

"""
Done!

Now error messages will be fancy!

To run this example uncomment one of the lines below to find the 
corresponding error message
"""

# Method Errors
# 1 - "a"

# nested errors
# fn(x::Int) = 2x
# other_fn(x) = fn(x) + fn(x)
# other_fn("a")


# DomainError
# sqrt(-1)

# AssertionError


import Term: Panel
# Panel("mytext", title="this title is waaaay too long!!!")
Panel(-6)





