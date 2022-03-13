import Term: make_logo

@testset "logo" begin
    @test_nowarn make_logo()
end