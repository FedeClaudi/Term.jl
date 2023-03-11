using Term
using Term.Annotations
import Term: highlight_syntax, TERM_THEME

Annotation(
    highlight_syntax("Panel(content; fit=true)"),
    "Panel" => ("this is the struct constructor call", TERM_THEME[].func),
    "content" => ("here you put what goes inside the panel", "white"),
    "fit=true" => (
        "Setting this as `true` adjusts the panel's width to fit `content`. Otherwise `Panel` will have a fixed width",
        "bright_blue",
    ),
) |> print

txt = """Annotation("main text", "this"=>"annotation: extra info", "main text"=>("with style", "green"))"""
ex = "\"to annotate\"=>(\"annotation message\", \"red\")"
ann = Annotation(
    highlight_syntax(txt),
    "Annotation" => ("constructor", TERM_THEME[].func),
    "main text" => "text to be annotated.\nSubstrings of this will be annotated with extra info.",
    "\"this\"=>\"annotation: extra info\"" => "simple annotation, no style. Just passed as a `Pair`",
    """"main text"=>("with style", "green"))""" => (
        "{white}annotation with extra style info: use a {red}`Tuple` to specify both the annotation's{/red} message and additional style info.{/white} For example:\n\n $(highlight_syntax(ex))",
        "bright_green",
    ),
)
