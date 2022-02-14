using Term



"""
    Mytype(::String, ::Vector{Int})

My types, it stores a `String` and an `Int`
"""
struct MyType
    a::String
    b::Int
end



my_obj = MyType("object instance", 21)
info(my_obj)

