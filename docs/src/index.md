```@meta
CurrentModule = Term
```
# Term

`Term.jl` is a Julia library for producing, styled and beautiful terminal output, like this:

```@example
import Term
print(Term.make_logo())
```

`Term.jl` uses a simple *markup* syntax to add style information to standard Julia strings.
It also provides `Renderable` objects such as the `Panel`s and `TextBox`es that you can see in the example below.
These too can be styled, and include styled text, but more importantly they can benested and stacked to produce
structured visual displays in your terminal. 


!!! warning "Code under development"
    While we're happy enough with `Term` to have people start using it, `Term` is a very young package under active development.
    This means that:
        1. there are likely several bugs that need to be discovered and fixed
        2. as we expand and improve `Term` there's likely going to be frequent breaking changes
    This means that if you're curious about `Term` and you'd like to start playing around with it, you're more than welcome to join the fun.
    Infact, you can join on us on [GitHub](https://github.com/FedeClaudi/Term.jl/discussions) and help us make `Term` even better!
    If, however, you're thinking of using `Term` in production-level code that others will need to rely upon, we ask you to be 
    patient for a bit longer as we continue to work on `Term`.


!!! info "`Term` and `rich`"
    While `Term` was written from scratch in Julia, it's based upon a pre-existing python library called [`rich`](https://github.com/Textualize/rich). If you have never used `rich`, jsut know that it's absolutely awesome. And its crator, Will McGugan, made it open source for anyone to use. That also meant people like us could took inspiration from `rich` to create related packages in other languages. We are very grateful to Will, and we hope that `Term` will end up beign a fraction as cool as `rich`.

### Installation
In a Julia script:
```Julia
using Pkd

Pkg.add("Term")
```

or in the Julia REPL
```
julia> ]  # enters the pkg interface
pkg> add Term
```

done!


----

The rest of the documentation is dedicated to explaining the basic concepts behavind `Term.jl` and how to use `Term` to produce styled terminal text. 
Head to the [GitHub](https://github.com/FedeClaudi/Term.jl) repository to find several detailed examples or jump in the [Discussions](https://github.com/FedeClaudi/Term.jl/discussions) to start chatting with us. 


!!! note "A note on `Rich`"
    Term.jl is based on a pre-existing package called `rich` (see [here](https://github.com/Textualize/rich)) developed by Will McGugan.
    While most of how `Term.jl` handles things under the hood is specific to `Term`, the basic concepts behind how to even begin creating fancy terminal
    outputs like the ones that `rich` and `Term` can produce are entirely Will's work. 

    We're very thankful to Will for making `rich`'s code open soruce and for the help and encouragement during the development of `Term`.


## Getting in touch
If you want to get in touch with us, the easiest way is on GitHub. You can open an [issue]() to report a bug or ask for a new feature or join the [discussions](https://github.com/FedeClaudi/Term.jl/discussions) for more general chats about `Term`. The discussion section is also a good place to go for general questions about `Term` and how to use it. 

`Term` is written to be a useful piece of software for anyone using Julia, from beginners to more advanced users. If you're comfortable writing and testing code, you can jump in right now and start actively working on `Term` with us. If you're not, that's totally fine. There's a lot of ways in which you can help: open an issue to report problems with `Term`, ask questions on GitHub, help expand the docs and examples for other users too. Or just tell us what you're experience using `Term` was like, any feedback is good feedback.

## Related packages
As mentioned, `Term` is inspired on `rich` in python. There's also a project called [Spectre console](https://spectreconsole.net/) which is a .NET Standard 2.0 version of `rich`.

In Julia there's several pre-existing packages aimed at producing styling terminal output, we note in particular:
- [Crayons](https://github.com/KristofferC/Crayons.jl)
- [AnsiColor](https://github.com/Aerlinger/AnsiColor.jl)