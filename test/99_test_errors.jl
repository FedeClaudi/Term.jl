import Term: install_term_stacktrace, TERM_SHOW_LINK_IN_STACKTRACE
import Term.Errors: error_message, StacktraceContext, render_backtrace

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

@testset "ERROR messages" begin
    @test error_message(ArgumentError("msg")) == "msg"
    @test error_message(AssertionError("msg")) == "msg"
    @test error_message(ErrorException("msg")) == "msg"
    @test error_message(DimensionMismatch("msg")) == "msg"

    @test error_message(DivideError()) == "Attempted integer division by {bold}0{/bold}"
    @test error_message(StackOverflowError()) ==
          "Stack overflow error: too many function calls."

    @test error_message(UndefKeywordError(:x)) ==
          "Undefined function keyword argument: `x`."
    @test error_message(KeyError(:test)) == "Key `test` not found!"
    @test error_message(UndefVarError(:x)) == "Undefined variable `x`."
    @test error_message(UndefVarError(:x)) == "Undefined variable `x`."
    @test error_message(StringIndexError("test", 21)) ==
          "attempted to access a String at index 21\n"

    @test error_message(InexactError(:round, Int, 1.5)) ==
          "Cannot convert 1.5 to type ::Int64\nConversion error in function: round"
    @test error_message(LoadError("test.jl", 21, ErrorException("msg"))) ==
          "At {grey62 underline}test.jl{/grey62 underline} line {bold}21{/bold}\nThe cause is an error of type: {red}ErrorException"
    @test error_message(BoundsError([1, 2], 3)) ==
          "Attempted to access a {#FFEE58}`Vector{{Int64}}`{/#FFEE58} width shape ({#90CAF9}2{/#90CAF9},) at index {#90CAF9}3{/#90CAF9}\n"
    @test error_message(DomainError(-1, "test")) == "test\nThe invalid value is: -1."
    @test error_message(TypeError(:Panel, "aa", Int, Float64)) ==
          "In `Panel` > `aa` got {#FFF59D bold}Float64{/#FFF59D bold}(::DataType) but expected argument of type ::Int64"

    @test error_message(MethodError(:print, (Panel, Int))) ==
          "(\"objects of type \", Symbol, \" are not callable\")\n \n{dim}No alternative candidates found"
    @test error_message(MethodError(print, (Panel, Int))) ==
          "No method matching {bold #42A5F5  bold}`print`{/bold #42A5F5  bold} with arguments types:\n{#CE93D8}::DataType{/#CE93D8}, {#CE93D8}::DataType{/#CE93D8}\n                       \nAlternative candidates:\n  \e[38;2;242;215;119mprint\e[39m(::Any...)      \n  \e[38;2;242;215;119mprint\e[39m(\e[31m::IO\e[39m, ::Any)   "
end

@testset "ERRORS - backtrace" begin
    f2(x) = 2x
    f1(x) = 3x
    f0(x; kwargs...) = begin
        st = stacktrace()
        ctx = StacktraceContext()
        bt = render_backtrace(ctx, st; kwargs...)
        return string(bt)
    end

    bt1 = f0(f2(f1(2)); hide_frames = true)
    bt2 = f0(f2(f1(2)); hide_frames = false)

    IS_WIN || @compare_to_string(string(bt1), "backtrace_1")
    IS_WIN || @compare_to_string(string(bt2), "backtrace_2")
end
