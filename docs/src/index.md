```@meta
CurrentModule = Term
```

`Term.jl` is a Julia library for producing, styled and beautiful terminal output, like this:

```@example
import Term
print(Term.make_logo())
```

`Term.jl` uses a simple *markup* syntax to add style information to standard Julia strings.
It also provides `Renderable` objects such as the `Panel`s and `TextBox`es that you can see in the example below.
These too can be styled, and include styled text, but more importantly they can benested and stacked to produce
structured visual displays in your terminal. 



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

The rest of the documentation is dedicated to explaining the basic concepts behavind `Term.jl` and how to use `Term` to produce styled terminal text. 
Head to the [GitHub](https://github.com/FedeClaudi/Term.jl) repository to find several detailed examples or jump in the [Discussions](https://github.com/FedeClaudi/Term.jl/discussions) to start chatting with us. 


``` note "A note on `Rich`
Term.jl is based on a pre-existing package called `rich` (see [here](https://github.com/Textualize/rich)) developed by Will McGugan.
While most of how `Term.jl` handles things under the hood is specific to `Term`, the basic concepts behind how to even begin creating fancy terminal
outputs like the ones that `rich` and `Term` can produce are entirely Will's work. 

We're very thankful to Will for making `rich`'s code open soruce and for the help and encouragement during the development of `Term`.
```