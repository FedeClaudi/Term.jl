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

@testset "\e[34mRenderables - RenderableText basic" begin
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore"
    r = RenderableText(lorem)

    @test size(r.measure) == (2, TEST_CONSOLE_WIDTH)

    r2 = RenderableText(r)
    @test size(r.measure) == (2, TEST_CONSOLE_WIDTH)

    width = 22
    r = RenderableText(lorem; width = width)
    @test string(r) ==
          "Lorem ipsum dolor     \nsit amet,             \nconsectetur           \nadipiscing elit, sed  \ndo eiusmod tempor     \nincididunt ut labore  "
    @test r.measure.w == width

    r = RenderableText(lorem; width = width, style = "red")
    @test string(r) ==
          "\e[31mLorem ipsum dolor     \e[39m\n\e[31msit amet,             \e[39m\n\e[31mconsectetur           \e[39m\n\e[31madipiscing elit, sed  \e[39m\n\e[31mdo eiusmod tempor     \e[39m\n\e[31mincididunt ut labore  \e[39m"
    @test r.measure.w == width

    @test string(RenderableText("a string")) == "a string"
    @test string(RenderableText("a\nstring")) == "a     \nstring"
end

@testset "\e[34mRenderables - RenderableText basic" begin
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore"
    width = 30

    IS_WIN || begin
        r = RenderableText(lorem, width = width, justify = :right)
        @compare_to_string(r, "renderable_text_1")

        r = RenderableText(lorem, width = width, justify = :center, background = "on_red")
        @compare_to_string(r, "renderable_text_2")
    end
end
