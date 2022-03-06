import Term.renderables: Renderable, RenderableText, AbstractRenderable

@testset "\e[31mRenderables - Renderable" begin
    # simply test the creation and type of Renderables
    @test Renderable("text") isa RenderableText

    r1 = Renderable("asdasda")
    @test Renderable(r1) isa AbstractRenderable
    @test Renderable(r1.segments[1]) isa AbstractRenderable

end


@testset "\e[31mRenderables - RenderableText" begin
    @test RenderableText("sadasdasdasdasdas") isa RenderableText

    r = RenderableText("a"^100; width=25)
    @test r.measure.w == 25
    @test r.measure.h == 4


    r = RenderableText("a"^100, "red bold"; width=25)
    @test r.measure.w == 25
    @test r.measure.h == 4

end