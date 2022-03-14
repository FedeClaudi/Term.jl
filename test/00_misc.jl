import Term: make_logo

@testset "logo" begin
    @test_nothrow make_logo()
end