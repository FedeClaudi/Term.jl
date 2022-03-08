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
        "Home"=> "index.md",
        "Manual" => [
            "Styled text"           => "01_styled_text.md",
            "Colors"                => "02_colors.md",
            "Renderables"           => "03_renderables.md",
            "Layout"                => "04_content_layout.md",
            "Logging"               => "05_logging.md",
            "Errors tracebacks"     => "06_errors_tracebacks.md",
            "Code introspection"    => "07_introspection.md",
        ],
        "API" => [
            "Term"          => "api_term.md",
            "Box"           => "api_box.md",
            "Color"         => "api_color.md",
            "Console"       => "api_console.md",
            "Inspect"       => "api_inspect.md",
            "Layout"        => "api_layout.md",
            "Logging"       => "api_logging.md",
            "Markup"        => "api_markup.md",
            "Measure"       => "api_measure.md",
            "Panel"         => "api_panel.md",
            "Renderables"   => "api_renderables.md",
            "Segment"       => "api_segment.md",
            "Style"         => "api_style.md",
        ],
    ],
)

deploydocs(; repo = "github.com/FedeClaudi/Term.jl", devbranch = "gh-pages")
