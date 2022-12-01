# Errors

In `Logging` we've seen how `Term` can replace the default logging system in Julia to produce stylized logging messages. `Term` can do the same for error messages and stack traces.


!!! warning "not for developers"
    Setting up Term's error handling will change this behavior for any downstream user of your code. While this could be okay, it might be surprising and undesirable for some, so do at your own risk. If you're writing code just for you, then go ahead! Term's error messages look great and hopefully they'll help finding and fixing errors more quickly.



Setting up `Term` to handle errors for you is very simple:
```Julia
import Term: install_term_stacktrace

install_term_stacktrace()  # entering the danger zone

function test()
    sum([])
end

test()


```

![](stacktrace.png)


!!! warning "Term is opinionated"
    In altering Julia's default stacktraces handling, a few choices where made such as: inveriting the order in which the backtrace's stack frames are shown and hiding frames from `Base` or other packages installed through `Pkg` (similarly to [AbbreviatedStackTraces.jl](https://github.com/BioTurboNick/AbbreviatedStackTraces.jl)).
    When installing `Term`'s stacktrace system with `install_term_stacktrace`, you can use the keyword arguments to alter this behavior
    
```@example
using Term # hide
install_term_repr() # hide
install_term_stacktrace
```