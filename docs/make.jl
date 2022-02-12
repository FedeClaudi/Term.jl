using Term
using Documenter

DocMeta.setdocmeta!(Term, :DocTestSetup, :(using Term); recursive=true)

makedocs(;
    modules=[Term],
    authors="FedeClaudi <federicoclaudi@protonmail.com> and contributors",
    repo="https://github.com/FedeClaudi/Term.jl/blob/{commit}{path}#{line}",
    sitename="Term.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://FedeClaudi.github.io/Term.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/FedeClaudi/Term.jl",
    devbranch="main",
)
