import Term.ansi: extract_markup

@testset "test ANSI simple" begin
    # test potential pitfalls in markup extraction for simple tags
    simple = "[red] just color [/red]"
    tags = extract_markup(simple)


    simple = "[ red] just color [/red]"


    simple = "[red] just color [/ red]"


    simple = "[red] just color [/red]"

end
