# [Term Repr](@id ReprDoc)
Note: by repr here we refer generically to how information about an object is represented in the terminal, not the `repr` function in Julia.

## Type REPR
You can use `Term.jl` to create a styled type display in your console. 

The easiest way to explain it is by way of example.
Let's say you define a type, and create an instance of it:

```@example repr


struct myType
    name::String
    height::Int
    width::Int
    mass::Float64
end


obj = myType("Rocket", 10, 10, 99.9)
```

as you can see the default way to represent your object in the console is not very exciting. 
But we can improve that with a simple macro!
```@example repr
using Term.Repr

@with_repr struct myFancyType
    name::String
    height::Int
    width::Int
    mass::Float64
end


obj = myFancyType("Rocket", 10, 10, 99.9)
```

now every time we display an instance of `myFancyType` in the console, we get a nice representation (note that that's not true for `print(obj)`!).


!!! warning "Docs display"
    Ooopss... it looks like the `Panel` display in the example above is not working out in the Docs. It will look fine in your REPL though!

## Termshow
Very nice, but what if I don't have access to where the types are created (perhaps they are in another package) but still want to have the nice display? One way is to use `termshow`:
```@example repr

dullobj = myType("Rocket", 10, 10, 99.9)
termshow(dullobj)
```

easy!

But wait, there's more!
```@example repr
termshow(termshow)  # or any other function
```

Fancy right? It shows the function, various methods for it and it's docstrings (by parsing the Markdown). It works with types too
```@example repr
import Term: Panel
termshow(Panel)
```

and in general you can display almost any object
```@example repr
termshow(Dict(:x => 1, :y => 2))
termshow(zeros(3, 3))
```

### install term repr
Okay, `termshow` is pretty cool (even if I say so myself), but we need to call it every time we need to display something. I just want to type a variable name in the REPL (devs are lazy you know). Well, there's a solution for that too of course:
```@example repr
install_term_repr()
Panel
```

now showing anything in the REPL goes through `termshow`

!!! warning "Not for developers!!!"
    If you're writing code just for yourself, go ahead and use `install_term_repr`. Enjoy it. But, if the code you're writing is intended for others you should really avoid doing that. It will modify the behavior of the REPL for them too and that's confusing and possibly error prone. 


## @showme
One of Julia's most loved features is multiple dispatch. However, sometimes it can be hard to know which method gets called by your code and what that method is doing. There's lots of tools out there to help with this, including some built in in Julia's base code. Here we show a nifty little macro that builds upon `CodeTracking` by Tim Holy to directly show you the method your code is calling:

```@example showme
import Term.Repr: @showme

@showme tprint(stdout, "this is TERM")  # which method is being called?
```

as you can see, it shows the source code of the particular `tprint` method being called by the combination of arguments, for different arguments different methods will be invoked:

```@example showme
@showme tprint("this is also TERM")  # different method
```

You can also list all methods for the function you're calling, should you wish to do so
```@example showme
@showme tprint("still TERM") show_all_methods=true
```

Enjoy.