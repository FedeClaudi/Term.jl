import Term: Measure



@testset "MEASURE stirng" begin

    a = "1234567"
    m = Measure(a)
    @test m.w == 7
    @test m.h == 1


    a = "1234567\n222"
    m = Measure(a)
    @test m.w == 7
    @test m.h == 2

    a = "1234567\n222\n"
    m = Measure(a)
    @test m.w == 7
    @test m.h == 3



    a = """


    test
    """
    m = Measure(a)
    @test m.w == 8
    @test m.h == 4


    a = """


test
    """
    m = Measure(a)
    @test m.w == 4
    @test m.h == 4
end