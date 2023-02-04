# [Annotation](@id AnnotationDocs)

I could describe what an `Annotation` is, but it's easier to show it:
```@example ann
using Term.Annotations

Annotation(
    "This is the main text to annotate",
    "main"=>"by main we mean most important, the rest is annotations",
    "annotate"=>"annotations are just extra bits of info"
)
```

as you can see, `Panel`s with extra messages are displayed underneath the main bit of text. 
Each "annotation" is defined by `Pair`, the first element of the `Pair` is a substring of the 
main text indicating what we want to annotate. The second element is used to specify what we
want to annotate it with. 

If you want to assign some `Style` information to each annotation, you can specify that by using a `Tuple{String, String}` as second element of the `Annotation` `Pair`. In this tuple, the first part refers to the annotation message while the second can store style information. 

```@example ann

Annotation("this has some style", "style"=>("style means color or stuff like bold", "bold red"))
```

and of course you can mix your normal `markup` style too:
Annotation("{bold italic}this{/bold italic} has some style", "style"=>("style means {bright_blue}color{/bright_blue} or stuff like {bold}bold{/bold}", "bold red")). 

---

`Annotation` objects are `AbstractRenderables`, so you can mix and match them with other things too. 
```@example ann
import Term: Panel, highlight_syntax

code = highlight_syntax("Annotation(\"main text\", \"main\"=>\"most important\")")

Panel(
    Annotation(code, "\"main text\""=>"main message to be annotated", "\"main\"=>\"most important\""=>"annotation");
    padding=(4, 4, 2, 1),
    title="Annotation: usage", fit=true, title_style="default green bold",
    title_justify=:center, style="green dim"
)
```
