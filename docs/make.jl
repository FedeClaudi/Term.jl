using Term, Documenter

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
        collapselevel = 1,
    ),
    pages = [
        "Home" => "index.md",
        "Basics" => Any[
            "basics/basics.md",    
            "basics/styled_text.md",
            "basics/colors.md",
            "basics/renderables.md",
            "basics/content_layout.md",
            "basics/tprint.md"
        ],
        "Advanced" => Any[
            "adv/adv.md",    
            "adv/progressbars.md",
            "adv/logging.md",
            "adv/errors_tracebacks.md",
            "adv/introspection.md",
        ],
        "API" => Any[
            "api/api_term.md",    
            "api/api_box.md",
            "api/api_color.md",
            "api/api_console.md",
            "api/api_errors.md",
            "api/api_introspection.md",
            "api/api_layout.md",
            "api/api_logging.md",
            "api/api_markup.md",
            "api/api_measure.md",
            "api/api_panel.md",
            "api/api_renderables.md",
            "api/api_segment.md",
            "api/api_style.md",
            "api/api_tprint.md",
        ],
    ],
)

deploydocs(; repo = "github.com/FedeClaudi/Term.jl")
