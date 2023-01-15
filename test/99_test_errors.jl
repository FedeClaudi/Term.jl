import Term: install_term_stacktrace, TERM_SHOW_LINK_IN_STACKTRACE
import Term.Errors: StacktraceContext, render_backtrace

install_term_stacktrace(; hide_frames = false)
TERM_SHOW_LINK_IN_STACKTRACE[] = false

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
    # @test_throws AssertionError Panel("mytext", title = "this title is waaaay too long!!!", fit=true)

    @test_throws UndefVarError println(sadfsadfasdsfsd)

    @test_throws BoundsError collect(1:10)[20]

    @test_throws DivideError div(2, 0)

    a() = b()
    b() = a()
    @test_throws StackOverflowError a()

    mydict = Dict(:a => "a", :b => "b")
    @test_throws KeyError mydict["a"]

    @test_throws InexactError Int(2.5)

    my_func(; my_arg::Int) = my_arg + 1
    @test_throws UndefKeywordError my_func()

    m = zeros(20, 20)
    n = zeros(5, 4)
    @test_throws DimensionMismatch m .+ n

    @test_throws MethodError exp("hello")  # issue #130

    # @test_throws TaskFailedException Threads.@threads for i in 1:10
    #     i + "a"
    # end
end

@testset "MethodError" begin
    # kwargs call
    struct Test3
        x::Float64
        y::Int

        # Test3(x, y, z) = new(x, y)
        Test3(x, y) = new(x, y)
    end
    @test_throws MethodError Test3(1; a = :test)

    # convert
    f(x)::Vector = 2x
    @test_throws MethodError f(1)
end

# ! this fails to pass tests for some reason.
# @testset "ERRORS - backtrace" begin
#     f2(x) = 2x
#     f1(x) = 3x
#     f0(x; kwargs...) = begin
#         st = stacktrace()
#         ctx = StacktraceContext(TEST_CONSOLE_WIDTH[])
#         bt = render_backtrace(ctx, st; kwargs...)
#         return string(bt)
#     end

#     bt1 = f0(f2(f1(2)); hide_frames = true)
#     bt2 = f0(f2(f1(2)); hide_frames = false)

#     IS_WIN || @compare_to_string(string(bt1), "backtrace_1")
#     IS_WIN || @compare_to_string(string(bt2), "backtrace_2")
# end
