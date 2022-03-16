import Term: make_logo

@testset "logo" begin
    @test_nothrow make_logo()

    logo = make_logo()
    @test logo.measure.w == 84
    @test logo.measure.h == 34

    testpanel(logo, 84, 34)
end