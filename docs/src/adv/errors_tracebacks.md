# Errors

In `Logging` we've seen how `Term` can replace the default logging system in Julia to produce stylized logging messages. `Term` can do the same for error messages and stack traces.


!!! warning "not for developers"
    Setting up Term's error handling will change this behavior for any downstream user of your code. While this could be okay, it might be surprising and undesirable for some, so do at your own risk. If you're writing code just for you, then go ahead! Term's error messages look great and hopefully they'll help finding and fixing errors more quickly.

Setting up `Term` to handle errors for you is very simple:
```Julia
import Term: install_term_stacktrace

install_term_stacktrace()  # entering the danger zone

1 + "this wont work"
```

![](stacktrace.png)

