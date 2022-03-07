using Term

import Pkg; Pkg.add("Documenter")
using Documenter

DocMeta.setdocmeta!(Term, :DocTestSetup, :(using Term); recursive = true)

makedocs(;
    modules = [Term],
    authors = "FedeClaudi <federicoclaudi@protonmail.com> and contributors",
    repo = "https://github.com/FedeClaudi/Term.jl/blob/{commit}{path}#{line}",
    sitename = "Term.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://FedeClaudi.github.io/Term.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "page.md",
        "Page title" => "page2.md",
        "Subsection" => [
            "p.md",
            "page12312.md",
            ]
        ],
)

deploydocs(; repo = "github.com/FedeClaudi/Term.jl", devbranch = "gh-pages")
