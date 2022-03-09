# Logging

Julia has a [great logging system](https://docs.julialang.org/en/v1/stdlib/Logging/). If you come from other programming languages like Python you'll likely already love it, but it can be better!

AS you know, if you use logging macros like `@info` with a bunch of arguments after, Julia produces something like this:

```Julia
@info "My log message" 1+1 n="a string!" :x
```

It shows your log messages and then the other arguments as `key = value` display even evaluating expressions like `1 + 1` and showing you the result. Very useful, but visually a bit dull. Also, we might want additional info to be shown: at what time was the log message produced, by which line of code, inside which function, what are the types of the arguments...

Well, `Term` provides logging functionality that gives all that information, plus a ton of styling on top. To do that we need to install `Term`'s own logger (`TermLogger`, very creative name) as the global logger to handle all error messages:

```Julia
import Term: install_term_logger
install_term_logger()
```

!!! note
    We could not get Documenter.jl to show the output of `Term`'s logger. So we've added a screenshot at the bottom of this page!

Done. Not a lot of work. Now you can just use your logging macros as you would normally, you don't need to change anything. But magic will happen:

```Julia
import Term: install_term_logger # hide
install_term_logger() # hide
@info "My log message" 1+1 n="a string!" :x
```

As you can see, it shows all the information that is normally there, an more! 
If your log macro is called from within a function, it will also tell you that:
```Julia
import Term: install_term_logger # hide
install_term_logger()  # hide

function my_useful_function()
    @info "My log message" 1+1 n="a string!" :x
end

my_useful_function()
```

And of course it works nicely with all logging macros:

```Julia
import Term: install_term_logger # hide
install_term_logger() # hide


@info "just some info"
@warn "careful!"
@error "uh oh, not good!"
```

![](logs.png)
