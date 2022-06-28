@testset "termshow fails on 1-by-1 matrices (#127)" begin
    @test termshow(IOBuffer(), hcat([1])) isa Nothing
end

@testset "termshow fails on datatypes (#129)" begin
    @test termshow(IOBuffer(), Int) isa Nothing
end
