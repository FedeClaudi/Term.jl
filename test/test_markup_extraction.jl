import Term.markup: extract_markup, MarkupTag


function test_extremes(tags, text)
    for tag in tags
        @test text[tag.open.start] == '['
        @test text[tag.open.stop] == ']'
        @test text[tag.close.start] == '['
        @test text[tag.close.stop] == ']'
    end
end

@testset "MARKUP TAGS EXTRACTION simple" begin
    
    @test length(extract_markup("no tags")) == 0

    simple = "[red] just color [/red]"
    tags = extract_markup(simple)
    test_extremes(tags, simple)
    @test length(tags) == 1
    @test typeof(tags[1]) == MarkupTag
    @test tags[1].markup == "red"
    @test tags[1].open.start == 1
    @test tags[1].open.stop == 5
    @test tags[1].close.start == 18


    simple = "[ red] just color [/ red]"
    tags = extract_markup(simple)
    test_extremes(tags, simple)
    @test length(tags) == 1
    @test tags[1].markup == " red"


    txt = "[red]text[/red]"
    @test length(extract_markup(txt)) == 1

    txt = "[red]text[/red][blue]resdfsd[/blue]"
    @test length(extract_markup(txt)) == 2
end


@testset "MARKUP TAGS EXTRACTION extra []" begin
    in_declaration = "[ [red] test [/red]"
    tags = extract_markup(in_declaration)
    test_extremes(tags, in_declaration)
    @test length(tags)==1

    in_declaration = "[ ]red] test [/red]"
    tags = extract_markup(in_declaration)
    test_extremes(tags, in_declaration)
    @test length(tags)==0

    escaped = "[[]] [red] test [/red]"
    tags = extract_markup(escaped)
    test_extremes(tags, escaped)
    @test length(tags)==1

    escaped = "[[ [red] test [/red]"
    tags = extract_markup(escaped)
    test_extremes(tags, escaped)
    @test length(tags)==1

    escaped = "]] [red] test [/red]"
    tags = extract_markup(escaped)
    test_extremes(tags, escaped)
    @test length(tags)==1
end


@testset "MARKUP TAGS EXTRACTION autoclose" begin
    txt = "[red] text"
    tags = extract_markup(txt)
    @test length(tags)==1

    txt = "[red] text[/]"
    tags = extract_markup(txt)
    test_extremes(tags, txt)
    @test length(tags)==1

    txt = "[red] text [/] [blue] test"
    tags = extract_markup(txt)
    @test length(tags)==2
    @test tags[1].markup == "red"
    @test tags[2].markup == "blue"
end


@testset "MARKUP TAGS EXTRACTION nested" begin
    txt = "[bold on_green]out [/][red] test [bold]  sdsdfds [/]"
    tags = extract_markup(txt)
    test_extremes(tags, txt)
    @test tags[1].markup == "bold on_green"
    @test tags[2].markup == "red"
    @test tags[3].markup == "bold"
    

    txt = "[red] osfsfs [blue] fefsfsd [on_red] sfsdfs [/on_red] fsdf[/blue] fsdfs[/red]"
    tags = extract_markup(txt)
    test_extremes(tags, txt)
    @test length(tags) == 3


    txt = "[red] osfsfs [blue] fefsfsd [on_red] sfsdfs [/on_red] fsdf[/] fsdfs"
    tags = extract_markup(txt)
    test_extremes(tags, txt)
    @test length(tags) == 3
end