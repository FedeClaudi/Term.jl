import Term: inspect
oldstd = stdout
redirect_stdout(open("/dev/null", "w"))

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

inspect(1)

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

redirect_stdout(oldstd) # recover original stdout
