# Intro

In the `Basics` section we've learned how to style text, create renderables and stack them into more complex layouts. You can use all of that to produce great terminal output for your Julia code, but that doesn't exhaust the range of things `Term` can do. 

In this section we'll have a look at `Term`'s additional functionality: `logging` discusses how to replace the default logging system in Julia to style logging messages with `Term`, `Errors` looks at how to replace the standard error messages with better ones made by `Term` and `introspection` will discuss `Term`'s `inspect` function which can be used to peek into objects in your Julia code.

Let's get started.
