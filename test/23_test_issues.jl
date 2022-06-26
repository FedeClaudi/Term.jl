@testset "termshow fails on 1-by-1 matrices (#127)" begin
    @test termshow(IOBuffer(), hcat([1])) isa Nothing
end
