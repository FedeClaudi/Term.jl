# Introspection

If you often use the (awesome) Julia REPL, you'll be familiar witht he fact that you can type `?` to enter the docs section. Then typing a name (e.g., of a `Type` or `function`) will bring up the relevant docs.
E.g. you might get something like this:

```
help?> cat
search: cat catch catch_backtrace vcat hcat hvcat hvncat CartesianIndex CartesianIndices CapturedException truncate @allocated @deprecate broadcast Broadcast broadcast! IndexCartesian

  cat(A...; dims)

  Concatenate the input arrays along the specified dimensions in the iterable dims. For dimensions not in dims, all input arrays should have the same size, which will also be the
  size of the output array along that dimension. For dimensions in dims, the size of the output array is the sum of the sizes of the input arrays along that dimension. If dims is a
  single number, the different arrays are tightly stacked along that dimension. If dims is an iterable containing several dimensions, this allows one to construct block diagonal
  matrices and their higher-dimensional analogues by simultaneously increasing several dimensions for every new input array and putting zero blocks elsewhere. For example,
  cat(matrices...; dims=(1,2)) builds a block diagonal matrix, i.e. a block matrix with matrices[1], matrices[2], ... as diagonal blocks and matching zero blocks away from the
  diagonal.

  See also hcat, vcat, hvcat, repeat.

  Examples
  ≡≡≡≡≡≡≡≡≡≡

  julia> cat([1 2; 3 4], [pi, pi], fill(10, 2,3,1); dims=2)
  2×6×1 Array{Float64, 3}:
  [:, :, 1] =
   1.0  2.0  3.14159  10.0  10.0  10.0
   3.0  4.0  3.14159  10.0  10.0  10.0
  
  julia> cat(true, trues(2,2), trues(4)', dims=(1,2))
  4×7 Matrix{Bool}:
   1  0  0  0  0  0  0
   0  1  1  0  0  0  0
   0  1  1  0  0  0  0
   0  0  0  1  1  1  1
```

This is super useful, you can get access to the docs directly in your console without having to go google stuff. But, if you're on `Terms` docs you're likely after a more stylish terminal experience. Can we do something like what `? print` does in the REPL, but with `Term`'s styling? Of course we can:

```@inspect
import Term: inspect

inspect(cat)
```

So given a function name, `inspect` prints out docstrings as well as methods signature. Just like `? vec` but with panels and colors. But it can also work with `Type`s:

```@example
import Term: inspect

abstract type AbstractType end

"""
    MyType

Just a type.
"""
struct MyType <: AbstractType
    x::Int
    y::String
end

"""
    Mytype(x::Int)

Construct MyType with only an `Int`
"""
MyType(x::Int) = MyType(x, "no string")

"""
    do_a_thing(a::MyType, x)

Function doing something with MyType
"""
do_a_thing(a::MyType, x) = print(a, x)
do_a_thing(a::MyType, x::MyType) = println(a, x)

# ! now inspect
inspect(MyType)
```

!!! warning
    Ooooops. It looks like the layout is a bit funky when rendered in the docs! It will look fine when you use `Term` in your REPL.

As you can see, with a `DataType` argument, `inspect` shows you the type's hierarchy for `MyType`, its docstring and where is defined as well as constructors for our custom type and methods that make use of `MyType` in their arguments. That's pretty much it, enjoy using `inspect`!


!!! note
    `inspect` accepts an optional keyword argument to choose how many constructors and methods to show: `max_n_methods::Int`. If an object has loads of methods, only the first `max_n_methods` will be shown.

