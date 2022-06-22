# Introspection
Introspection refers to code that looks into another bit of code (or itself) to give you more details about it. The easiest way, with Term, is to use the [Term Repr](@ref ReprDoc) functionality and use `termshow` to get all the details you need. But there's dedicated code to analyse `Expr` objects in more details

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
