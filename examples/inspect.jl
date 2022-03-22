"""
    This example shows how to use Term's introspection functionality.

Introspection refers to a piece of code analyzing another piece of code.
Say you want to know what a custom data type is like, or what methods does
a function have etc... What would you do? You can have a look at the docs, you
can go on the GitHub repository and look around, or yo can use Term!

Term provides an `inspect` method that provides a lot of useful information!
"""

import Term: inspect, typestree

# define some types
abstract type T1 end

abstract type T2 <: T1 end

"""§§
    MyType

It's just a useless type we've defined to provide an example of
Term's awesome `inspect` functionality!
"""
struct MyType <: T2
    x::Int
    y::String
    fn::Any
end

#  Now, what is MyType like?
inspect(MyType)

# Let's define some constructors and methods using MyType

"""
constructors!
"""
MyType(x::Int) = MyType(x, "no string", nothing)

MyType(x::Int, y) = MyType(x, y, nothing)

# methods
useless_method(m::MyType) = m

"""
these methods don't do much, just an example
"""
another_method(m1::MyType, m2::MyType) = print(m1, m2)

# let's inspect MyType again!
inspect(MyType)

"""
Not bad huh !?
It also works with instances of types
"""

inspect(MyType(2))

"""
And for abstract types of course1
"""

inspect(T2)

"""
finally, you can also use inspect to look at functions.
Let's get a bit meta
"""

inspect(inspect)

"""
as you can see inspect prints the docstrings of the methods it can find and lists some of 
the methods available.
"""

"""
If you just want to see the type's hierarchy for a type, you can use typestree
"""

typestree(AbstractFloat)