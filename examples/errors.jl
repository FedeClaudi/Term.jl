"""

    This example show's how to use Term's errors functionality


Term provides functionality to produce styled and informative error
messages and tracestacks. This is not active by default as not everybody
might want this, but it's easier to turn on.

NOTE: this is a preliminary feature, there might be bugs and not all error
types may be correctly represented. While generally useful, it might be best
to hold back on this feature for code that needs to reliably print accurate
error information.
"""

import Term: install_term_stacktrace, hLine

install_term_stacktrace()
install_term_logger()
print(hLine("Fancy Errors"; style = "bold blue"))

"""
Done!

Now error messages will be fancy!

To run this example uncomment one of the lines below to find the 
corresponding error message
"""

# ------------  MethodError
# 1 - "a"

# ------------  DomainError
# sqrt(-1)

# ------------  UndefVarError
# println(x)

# ------------  BoundsError
# v = collect(1:10)
# v[20]

# ------------  DivideError
# div(2, 0)

# ------------  StackOverflowError
# a() = b()
# b() = a()
# a()

# ------------  KeyError
# mydict = Dict(:a=>"a", :b=>"b")
# mydict["a"]

# ------------  InexactError
# Int(2.5)

# ------------  UndefKeywordError
# function my_func(;my_arg::Int)
#     return my_arg + 1
# end
# my_func()

# ------------  DimensionMismatch
m = zeros(20, 20)
n = zeros(5, 4)
m .+ n

# ------------  Errors with type creation

struct MyType
    x::Int
    y
    z::String
end

MyType(x::Int, y::Int) = MyType(x, y, 1)
MyType(x::Int) = MyType(x, 0)

MyType(1)
