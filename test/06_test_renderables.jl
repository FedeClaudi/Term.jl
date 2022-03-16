import Term.renderables: Renderable, RenderableText, AbstractRenderable
import Term.segment: Segment
import Term: fillin

@testset "\e[34mSegment" begin
    seg = Segment("test", nothing)
    @test seg.text == "test"
    @test seg.plain == "test"
    @test seg.measure.w == 4

    @test_nothrow println(seg)

    seg = Segment("test", "red")
    @test seg.text == "\e[31mtest\e[39m"
    @test seg.plain == "test"
    @test seg.measure.w == 4

    seg = Segment("aa\n123")
    @test seg.measure.w == 3
    @test seg.measure.h == 2
end

@testset "\e[34mRenderables - Renderable" begin
    # simply test the creation and type of Renderables
    @test Renderable("text") isa RenderableText

    r1 = Renderable("asdasda")
    @test Renderable(r1) isa AbstractRenderable
    @test Renderable(r1.segments[1]) isa AbstractRenderable


    r = Renderable("x".^10)
    @test r.measure.w == 10
    @test r.measure.h == 1

    r = Renderable(".\n".^10)
    @test r.measure.w == 1
    @test r.measure.h == 11
end



@testset "\e[34mRenderables - RenderableText" begin
    @test RenderableText("sadasdasdasdasdas") isa RenderableText

    r = RenderableText("a"^100; width = 25)
    @test r.measure.w == 25
    @test r.measure.h == 4

    r = RenderableText("a"^100, "red bold"; width = 25)
    @test r.measure.w == 25
    @test r.measure.h == 4

    r = RenderableText("a"^500, "red bold")
    @test r.measure.w == displaysize(stdout)[2]


    r = RenderableText(RenderableText("a"^500, "blue"), "red bold")
    @test r.measure.w == displaysize(stdout)[2]

    r = RenderableText(RenderableText("a"^5, "blue"), "red bold")
    @test string(r) == "\e[1m\e[31maaaaa\e[22m\e[39m"


    # segments reshaping
    a = RenderableText("asdasd
    asdasdasda
    asdasdasda
ASDFADADASsadfafsfgs§dfsf")

    widths = [seg.measure.w for seg in a.segments]
    @test length(unique(widths)) == 1
    
end
