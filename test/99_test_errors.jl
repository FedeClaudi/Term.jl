import Term: install_stacktrace

install_stacktrace()

"""
The logic behind these tests is that if something goes
wrong during the error message generation, the 
exception returned by the test
will be different from the one you'd expect
"""

@testset "\e[34mERRORS" begin
    @test_throws MethodError 1 - "a"

    @test_throws DomainError √(-1)

    import Term: Panel
    @test_throws AssertionError Panel("mytext", title = "this title is waaaay too long!!!", fit=true)

    @test_throws UndefVarError println(x)

    @test_throws BoundsError collect(1:10)[20]

    @test_throws DivideError div(2, 0)

    a() = b()
    b() = a()
    @test_throws StackOverflowError a()

    mydict = Dict(:a => "a", :b => "b")
    @test_throws KeyError mydict["a"]

    @test_throws InexactError Int(2.5)

    function my_func(; my_arg::Int)
        return my_arg + 1
    end
    @test_throws UndefKeywordError my_func()

    m = zeros(20, 20)
    n = zeros(5, 4)
    @test_throws DimensionMismatch m .+ n
end
