import Term: make_logo

@testset "logo" begin
    @test_nothrow make_logo()

    logo = make_logo()
    @test logo.measure.w == 76
    @test logo.measure.h == 29

    testpanel(logo, 76, 29)
end