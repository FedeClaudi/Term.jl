# Introspection
Introspection refers to code that looks into another bit of code (or itself) to give you more details about it. 

!!! tip "Check out REPR"
    The easiest way to do introspection with Term is to use the [Term Repr](@ref ReprDoc) functionality including functions such as  `termshow` and `@showme` to get all the details you need about your Julia code. Head over there to find out more. 

## `inspect`
You're using a new library, trying to get a hold of the different types they've defined and how they're used. We've all been there, it can take a while and be quite confusing. 
Term to the rescue!

You can now use `inspect(T::DataType)` to get all information you possibly need about a type `T` (and some more). You get: docstring, definition, constructor methods, methods using `T` and methods using `T`'s supertypes. It can be quite a lot of stuff, so you can use some conveniently placed tags to choose what you want to see:


```@meta
CurrentModule = Term.Introspection
```

```@docs
inspect
```

Try, for example: `using Term; inspect(Panel, documentation=true)`.

## `typestree`
As you know, one of Julia's defining features is its hierarchical types structure. Sometimes, you want to get an overview of this hierarchy but there isn't always a convenient way achieve that... or is there...

```@example
import Term: typestree

print(typestree(Float64))

```



## Expression & `expressiontree`
If you're doing a bit of metaprogramming (or teaching it to new Julia coders), you want to get an idea of what the parts of the `Expr` you're building are. You can use `expressiontree` to get a [Tree](@ref TreeDoc) based visualization:

```@example
import Term: expressiontree
expr = :(2x + √x^y)
expressiontree(expr)
```

enjoy!
