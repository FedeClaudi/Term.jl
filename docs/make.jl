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
        "Home"                  => "index.md",
        "styled text"           => "styled_text.md",
        "panels"                => "panels.md",
        "content layout"        => "content_layout.md",
        "logging"               => "logging.md",
        "errors tracebacks"     => "errors_tracebacks.md",
        "code introspection"    => "introspection.md",
    ],
)

deploydocs(; repo = "github.com/FedeClaudi/Term.jl", devbranch = "gh-pages")
