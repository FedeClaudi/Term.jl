import Term: make_logo, @with_repr

@testset "logo" begin
    @test_nothrow make_logo()

    logo = make_logo()
    @test logo.measure.w == 84
    @test logo.measure.h == 28
end


@testset "REPR" begin
    @with_repr struct Rocket
        width::Int
        height::Int
        mass::Float64
        
        manufacturer::String
    end
    
    obj = Rocket(10, 50, 5000, "NASA")
end
