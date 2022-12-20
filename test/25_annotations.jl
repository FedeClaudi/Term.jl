using Term.Annotations
import Term: highlight_syntax, TERM_THEME


@testset "Annotations" begin
    ann = Annotation(
        highlight_syntax("Panel(content; fit=true)"), 
            "Panel" => ("this is the struct constructor call", TERM_THEME[].func),
            "content"=>("here you put what goes inside the panel", "white"), 
            "fit=true"=>("Setting this as `true` adjusts the panel's width to fit `content`. Otherwise `Panel` will have a fixed width", "blue_light"),
    ) 
    IS_WIN || @compare_to_string(ann, "annotations_1")


    ann = Annotation("This is an example of an annotation to display nicely some info", 
        "example"=>"very simple but important, pay attention!", 
        "annotation"=>("is it \nhelpful?", "blue"),
        "some info" => ("hopefully useful", "italic green"),
        )   
    IS_WIN || @compare_to_string(ann, "annotations_2")


    ann = Annotation("{red}This is an example of an annotation to {bold}display{/bold} nicely some info{/red}", 
        "example"=>"very simple but important, pay attention!", 
        "annotation"=>("is it \nhelpful?", "blue"),
        "some info" => ("hopefully useful", "italic green"),
        )   
    IS_WIN || @compare_to_string(ann, "annotations_3")

    ann = Annotation("{white}This is an example of an annotation to {bold}display{/bold} nicely some info{/white}", 
        "some info" => ("hopefully useful", "italic green"),
        "example"=>"very simple but important, pay attention!", 
        "annotation"=>("is it helpful? This is a very long message to check that everything is working {red}correctly{/red}", "default"),
        )   
    IS_WIN || @compare_to_string(ann, "annotations_4")

end