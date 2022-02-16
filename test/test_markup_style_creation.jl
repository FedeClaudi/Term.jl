import Term: MarkupStyle
import Term.markup: extract_markup
import Term.color: NamedColor, RGBColor, BitColor

@testset "MarkupStyle" begin
    text = "tsers[red bold dim] rsers[/]"
    tag = extract_markup(text)[1]
    style = MarkupStyle(tag)


    @test style.bold ==  true
    @test style.dim ==  true
    @test style.italic == false
    @test style.underline == false
    @test style.blink == false
    @test style.inverse == false
    @test style.hidden == false
    @test style.striked == false
    @test style.color == NamedColor("red")
    @test style.background == nothing
    @test style.tag == tag


    text = "tsers[medium_spring_green underline blink italic] rsers[/]"
    tag = extract_markup(text)[1]
    style = MarkupStyle(tag)


    @test style.bold ==  false
    @test style.dim ==  false
    @test style.italic == true
    @test style.underline == true
    @test style.blink == true
    @test style.inverse == false
    @test style.hidden == false
    @test style.striked == false
    @test style.color == BitColor("medium_spring_green")
    # @test style.background == NamedColor("blue")
    @test style.tag == tag



    text = "tsers[red on_blue hidden] rsers[/]"
    tag = extract_markup(text)[1]
    style = MarkupStyle(tag)

    @test style.hidden == true
    @test style.color == NamedColor("red")
    @test style.background == NamedColor("blue")
    @test style.tag == tag



    text = "tsers[(.1,.4,.1) on_(255, 12, 2) blink] rsers[/]"
    tag = extract_markup(text)[1]
    style = MarkupStyle(tag)
    @test style.color == RGBColor("(.1,.4,.1)")
    @test style.background == RGBColor("(255,12,2)")

    @test style.blink == true
    @test style.color == RGBColor("(.1,.4,.1)")
    @test typeof(style.background) == RGBColor


    text = "tsers[turquoise2 on_pale_green3 blink] rsers[/]"
    tag = extract_markup(text)[1]
    style = MarkupStyle(tag)

    @test style.blink == true
    @test style.color == BitColor("turquoise2")
    @test style.background == BitColor("pale_green3")
end