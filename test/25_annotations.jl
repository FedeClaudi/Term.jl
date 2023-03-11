using Term.Annotations
import Term: highlight_syntax, TERM_THEME, Panel

@testset "Annotations" begin
    ann = Annotation(
        highlight_syntax("Panel(content; fit=true)"),
        "Panel" => ("this is the struct constructor call", TERM_THEME[].func),
        "content" => ("here you put what goes inside the panel", "white"),
        "fit=true" => (
            "Setting this as `true` adjusts the panel's width to fit `content`. Otherwise `Panel` will have a fixed width",
            "blue_light",
        ),
    )
    IS_WIN || @compare_to_string(ann, "annotations_1")

    ann = Annotation(
        "This is an example of an annotation to display nicely some info",
        "example" => "very simple but important, pay attention!",
        "annotation" => ("is it \nhelpful?", "blue"),
        "some info" => ("hopefully useful", "italic green"),
    )
    IS_WIN || @compare_to_string(ann, "annotations_2")

    ann = Annotation(
        "{red}This is an example of an annotation to {bold}display{/bold} nicely some info{/red}",
        "example" => "very simple but important, pay attention!",
        "annotation" => ("is it \nhelpful?", "blue"),
        "some info" => ("hopefully useful", "italic green"),
    )
    IS_WIN || @compare_to_string(ann, "annotations_3")

    ann = Annotation(
        "{white}This is an example of an annotation to {bold}display{/bold} nicely some info{/white}",
        "some info" => ("hopefully useful", "italic green"),
        "example" => "very simple but important, pay attention!",
        "annotation" => (
            "is it helpful? This is a very long message to check that everything is working {red}correctly{/red}",
            "default",
        ),
    )
    IS_WIN || @compare_to_string(ann, "annotations_4")

    ann = Annotation(
        "{bold italic}this{/bold italic} has some style",
        "style" => (
            "style means {bright_blue}color{/bright_blue} or stuff like {bold}bold{/bold}",
            "bold red",
        ),
    )
    IS_WIN || @compare_to_string(ann, "annotations_5")

    code = highlight_syntax("Annotation(\"main text\", \"main\"=>\"most important\")")
    ann = Panel(
        Annotation(
            code,
            "\"main text\"" => "main message to be annotated",
            "\"main\"=>\"most important\"" => "annotation",
        );
        padding = (4, 4, 2, 1),
        title = "Annotation: usage",
        fit = true,
        title_style = "default green bold",
        title_justify = :center,
        style = "green dim",
    )
    IS_WIN || @compare_to_string(ann, "annotations_6")

    TERM_THEME[].annotation_color = "white"
    txt = """Annotation("main text", "this"=>"annotation: extra info", "main text"=>("with style", "green"))"""
    @test_throws AssertionError Annotation(
        highlight_syntax(txt),
        "Annotation" => "constructor",
        "main text" => "text to be annotated",
        "\"this\"=>\"annotation: extra info\"" => "simple annotation, no style",
        """"main text"=>("with style", "green"))""" => "annotation with extra style info",
    )
    # IS_WIN || @compare_to_string(ann, "annotations_7")

    # ann = Annotation(
    #     highlight_syntax(txt),
    #     "Annotation" => "contructor",
    #     "main text" => "text to be annotated.\nSubstrings of this will be annotated with extra info.",
    #     "\"this\"=>\"annotation: extra info\"" => "simple annotation, no style",
    #     """"main text"=>("with style", "green"))""" => "annotation with extra style info",
    # )
    # IS_WIN || @compare_to_string(ann, "annotations_8")

    # ex = "\"to annotate\"=>(\"annotation message\", \"red\")"
    # ann = Annotation(
    #     highlight_syntax(txt),
    #     "Annotation" => ("contructor", TERM_THEME[].func),
    #     "main text" => "text to be annotated.\nSubstrings of this will be annotated with extra info.",
    #     "\"this\"=>\"annotation: extra info\"" => "simple annotation, no style. Just passed as a `Pair`",
    #     """"main text"=>("with style", "green"))""" => (
    #         "annotation with extra style info: use a `Tuple` to specify both the annotation's message and additional style info. For example:\n\n $(highlight_syntax(ex))",
    #         "bright_green",
    #     ),
    # )
    # IS_WIN || @compare_to_string(ann, "annotations_9")
end
