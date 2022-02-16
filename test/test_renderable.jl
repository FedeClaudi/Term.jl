import Term: Renderable, Segment, Segments, Measure

≡(m1, m2) = m1.w == m2.w && m1.h == m2.h

@testset "Renderable" begin
    # create segments
    s1 = Segment("[red]test")
    s2 = Segment("[blue on_red]test[/]")
    s3 = Segment(s1)

    @test s1.measure ≡ Measure("[red]test")
    @test Measure("[red]test").w == 4

    # create renderables
    r1 = Renderable(s1)
    @test r1.measure ≡ s1.measure
    @test Renderable("[red]test[/red]").measure ≡ s1.measure

    r2 = Renderable(s2)
    @test r2.measure ≡ r1.measure

    rr = r1 + r2
    @test rr.measure ≡ r1.measure + r2.measure

    @test r1 == Renderable(r1)
end