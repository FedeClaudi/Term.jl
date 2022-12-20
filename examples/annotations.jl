using Term
using Term.Annotations
import Term: highlight_syntax, TERM_THEME

Annotation(
    highlight_syntax("Panel(content; fit=true)"),
    "Panel" => ("this is the struct constructor call", TERM_THEME[].func),
    "content" => ("here you put what goes inside the panel", "white"),
    "fit=true" => (
        "Setting this as `true` adjusts the panel's width to fit `content`. Otherwise `Panel` will have a fixed width",
        "blue_light",
    ),
) |> print
