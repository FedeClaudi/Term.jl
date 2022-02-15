import Term: Measure



@testset "MEASURE string" begin

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


@testset "MEASURE sum" begin

    a = "1234567"
    m1 = Measure(a)  # 7, 1


    a = "1234567\n222"
    m2 = Measure(a)  # 7, 2

    
    a = """


    test
    """
    m3 = Measure(a) # 8, 4

    @test m1 + m2 == Measure(7, 2)
    @test m1 + m2 + m3 == Measure(8, 4)
end