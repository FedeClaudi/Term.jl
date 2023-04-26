```@meta
CurrentModule = Term
```
# Term

`Term.jl` is a Julia library for producing styled, beautiful terminal output. 
It uses a simple *markup* syntax to add style information to standard Julia strings.
It also provides `Renderable` objects such as the `Panel` and `TextBox` as you can see in the example below.
These too can be styled, include styled text, and they can be nested and stacked to produce
structured visual displays in your terminal. 


!!! warning "Version 1.0"
    If you're an early adopter of Term, I have some bad news for you (and some good). Version `1.0` introduces some breaking changes. I know, I know. But it's worth it, I promise, and it has a ton of new features and improvements. The main thing you need to look out for is the markup syntax. Instead of `[...] content [/...]` now you need to use `{...} content {/...}`. That's right, curly braces instead of square. It's not a huge change!

!!! warning "OS concerns"
    `Term` has been tested extensively so far, but only on Mac. If you're using a Linux or Windows machine you might find some bugs that have eluded us so far. Please get in touch so that we can fix them!

!!! info "`Term` and `rich`"
    While `Term` was written from scratch in Julia, it's based upon a pre-existing python library called [`rich`](https://github.com/Textualize/rich). If you have never used `rich`, just know that it's absolutely awesome. And its creator, Will McGugan, made it open source for anyone to use. That also meant people like us could take inspiration from `rich` to create related packages in other languages. We are very grateful to Will, and we hope that `Term` will end up being a fraction as cool as `rich`.

### Installation
In a Julia script:
```Julia
using Pkg

Pkg.add("Term")
```

or in the Julia REPL
```
julia> ]  # enters the pkg interface
pkg> add Term
```

done!


----

The rest of the documentation is dedicated to explaining the basic concepts behind `Term.jl` and how to use `Term` to produce styled terminal text. 
Head to the [GitHub](https://github.com/FedeClaudi/Term.jl) repository to find several detailed examples or jump in the [Discussions](https://github.com/FedeClaudi/Term.jl/discussions) to start chatting with us. 



## Getting in touch
If you want to get in touch with us, the easiest way is on GitHub. You can open an [issue](https://github.com/FedeClaudi/Term.jl/issues) to report a bug or ask for a new feature or join the [discussions](https://github.com/FedeClaudi/Term.jl/discussions) for more general chats about `Term`. The discussion section is also a good place to go for general questions about `Term` and how to use it. 

`Term` is written to be a useful piece of software for anyone using Julia, from beginners to more advanced users. If you're comfortable writing and testing code, you can jump in right now and start actively working on `Term` with us. If you're not, that's totally fine. There are a lot of ways in which you can help: open an issue to report problems with `Term`, ask questions on GitHub, help expand the docs and examples for other users too. Or just tell us what you're experience using `Term` was like, any feedback can help us improve!

## Related packages
As mentioned, `Term` is inspired on `rich` in python. There's also a project called [Spectre console](https://spectreconsole.net/) which is a .NET Standard 2.0 version of `rich`.

In Julia there are several pre-existing packages aimed at producing styling terminal output; we note in particular:
- [Crayons](https://github.com/KristofferC/Crayons.jl)
- [AnsiColor](https://github.com/Aerlinger/AnsiColor.jl)
