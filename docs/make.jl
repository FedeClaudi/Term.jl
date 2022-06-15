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
    strict = false,
    pages = [
        "Home" => "index.md",
        "Basics" => Any[
            "basics/basics.md",
            "basics/styled_text.md",
            "basics/colors_and_theme.md", # TODO add theme
            "basics/renderables.md",
            "basics/tprint.md",  # TODO add info about highlighting
        ],
        "Renderables" => Any[
            "ren/intro.md",
            "ren/text.md",
            "ren/panel.md",
            "ren/table.md",            
            "ren/layout_rens.md",
            "ren/dendogram.md",
            "ren/tree.md",
        ],
        "Layout" => Any[
            "layout/layout.md",
            "layout/nesting.md",
            "layout/stacking.md",
            "layout/justify.md",
            "layout/grid.md",
            "layout/compositor.md",
        ],
        "Advanced" => Any[
            "adv/adv.md",
            "adv/repr.md",
            "adv/progressbars.md",
            "adv/logging.md",
            "adv/errors_tracebacks.md",  # TODO update screenshot
            "adv/introspection.md",
            "adv/markdown.md",
        ],
        "Examples" => Any[
            "examples/examples.md",  # TODO add examples cards
        ],
        "API" => Any[
            "api/api_term.md",
            "api/api_boxes.md",
            "api/api_colors.md",
            "api/api_console.md",
            "api/api_compositors.md",
            "api/api_dendograms.md",
            "api/api_errors.md",
            "api/api_introspection.md",
            "api/api_layout.md",
            "api/api_logs.md",
            "api/api_markdown.md",
            "api/api_measures.md",
            "api/api_panels.md",
            "api/api_renderables.md",
            "api/api_repr.md",
            "api/api_segments.md",
            "api/api_style.md",
            "api/api_tprint.md",
            "api/api_trees.md",
        ],
    ],
)

deploydocs(; repo = "github.com/FedeClaudi/Term.jl")
