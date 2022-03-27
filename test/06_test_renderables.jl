import Term.renderables: Renderable, RenderableText, AbstractRenderable
import Term.segment: Segment
import Term: fillin

@testset "\e[34mSegment" begin
    seg = Segment("test", "default")
    @test seg.text == "\e[22mtest\e[22m"
    @test seg.measure.w == 4

    @test_nothrow println(seg)

    seg = Segment("test", "red")
    @test seg.text == "\e[31mtest\e[39m"
    @test seg.measure.w == 4

    seg = Segment("aa\n[blue]123[/blue]")
    @test seg.measure.w == 3
    @test seg.measure.h == 2


    seg = Segment("test")
    @test seg * "test" isa Segment
    @test (seg*"t2").text == "testt2"
    @test ("t2"*seg).text == "t2test"
    @test (seg*seg).text == "testtest"
end

@testset "\e[34mRenderables - Renderable" begin
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore"
    r = RenderableText(lorem)

    @test r.measure.w == 99
    @test r.measure.h == 1

    r2 = RenderableText(r)
    @test r.measure.w == 99
    @test r.measure.h == 1

    r = RenderableText(lorem; width=22)
    @test string(r) == "Lorem ipsum dolor sit \namet, consectetur     \nadipiscing elit, sed  \ndo eiusmod tempor     \nincididunt ut         \nlabore                "
    @test r.measure.w == 22

    r = RenderableText(lorem; width=22, style="red")
    @test string(r) == "\e[31mLorem ipsum dolor sit \e[39m\n\e[31mamet, consectetur     \e[39m\n\e[31madipiscing elit, sed  \e[39m\n\e[31mdo eiusmod tempor     \e[39m\n\e[31mincididunt ut         \e[39m\n\e[31mlabore                \e[39m"
    @test r.measure.w == 22
end

