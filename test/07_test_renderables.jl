import Term.Renderables: Renderable, RenderableText, AbstractRenderable, trim_renderable
import Term: Panel
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

    s = @capture_out show(seg)
    @test s == string(s)
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
        "Lorem ipsum dolor     \nsit amet, consectetur \n adipiscing elit,     \nsed do eiusmod tempor \n incididunt ut labore "
    @test r.measure.w == width

    r = RenderableText(lorem; width = width, style = "red")
    @test string(r) ==
        "\e[31mLorem ipsum dolor     \e[39m\n\e[31msit amet, consectetur \e[39m\n\e[31m adipiscing elit,     \e[39m\n\e[31msed do eiusmod tempor \e[39m\n\e[31m incididunt ut labore \e[39m"
    @test r.measure.w == width

    @test string(RenderableText("a string")) == "a string"
    @test string(RenderableText("a\nstring")) == "a     \nstring"

    @test_nothrow @capture_out show(r)
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

@testset "\e[34mRenderables - trim renderables" begin
    IS_WIN || begin
        r = trim_renderable(RenderableText("aa bb"^100), 25)
        @compare_to_string(r, "trim_renderables_1")

        r = trim_renderable(Panel("aa bb"^100), 25)
        @compare_to_string(r, "trim_renderables_2")
    end
end
