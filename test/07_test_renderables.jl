import Term.Renderables: Renderable, RenderableText, AbstractRenderable
import Term.Segments: Segment
import Term: fillin

@testset "\e[34mSegment" begin
    seg = Segment("test", "default")
    @test seg.text == "\e[22mtest\e[22m"
    @test seg.measure.w == 4

    @test_nothrow println(seg)

    seg = Segment("test", "red")
    @test seg.text == "\e[31mtest\e[39m"
    @test seg.measure.w == 4

    seg = Segment("aa\n{blue}123{/blue}")
    @test size(seg.measure) == (2, 3)

    seg = Segment("test")
    @test seg * "test" isa Segment
    @test (seg * "t2").text == "testt2"
    @test ("t2" * seg).text == "t2test"
    @test (seg * seg).text == "testtest"
end

@testset "\e[34mRenderables - Renderable" begin
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore"
    r = RenderableText(lorem)

    @test size(r.measure) == (1, length(lorem))

    r2 = RenderableText(r)
    @test size(r.measure) == (1, length(lorem))

    width = 22
    r = RenderableText(lorem; width = width)
    @test string(r) ==
          "Lorem ipsum dolor sit \e[0m\namet, consectetur \e[0m    \nadipiscing elit, sed \e[0m \ndo eiusmod tempor \e[0m    \nincididunt ut labore  "
    @test r.measure.w == width

    r = RenderableText(lorem; width = width, style = "red")
    @test string(r) ==
          "\e[31mLorem ipsum dolor sit \e[0m\e[39m\n\e[31mamet, consectetur \e[0m    \e[39m\n\e[31madipiscing elit, sed \e[0m \e[39m\n\e[31mdo eiusmod tempor \e[0m    \e[39m\n\e[31mincididunt ut labore  \e[39m"
    @test r.measure.w == width

    @test string(RenderableText("a string")) == "a string"
    @test string(RenderableText("a\nstring")) == "a     \nstring"
end
