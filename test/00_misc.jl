import Term: make_logo, @with_repr, termshow

@testset "logo" begin
    @test_nothrow make_logo()

    logo = make_logo()
    dotest && @test logo.measure.w == 84
    @test logo.measure.h == 28
end
