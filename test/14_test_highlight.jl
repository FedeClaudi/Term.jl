import Term: load_code_and_highlight, highlight_syntax, highlight, theme


@testset "\e[34mHIGHLIGHT" begin

    @test_nothrow highlight("test 1 123 33.4 44,5 +1 -2 12 0.5, ,, ...") == "test[#90CAF9][#90CAF9] 1 [/#90CAF9][/#90CAF9][#90CAF9]123[/#90CAF9] [#90CAF9]33.4[/#90CAF9] [#90CAF9]44,5[/#90CAF9] [#90CAF9]+1 [/#90CAF9][#90CAF9]-2 [/#90CAF9][#90CAF9]12[/#90CAF9] [#90CAF9]0.5[/#90CAF9][#90CAF9], [/#90CAF9],[#90CAF9], [/#90CAF9]..."

    @test_nothrow highlight("this is ::Int64") == "this is [#d880e7]::Int64[/#d880e7]"

    @test_nothrow highlight("print", :func) == "[#fff126]print[/#fff126]"

    @test_nothrow highlight("1 + 2", :code) == "[#ffd77a]1 + 2[/#ffd77a]"

    @test_nothrow highlight("this 1 + `test`") == "this 1 + [#ffd77a]`test`[/#ffd77a]"

    @test_nothrow highlight(1)

    @test_nothrow highlight([1, 2, 3])

    @test_nothrow highlight(Int)

    @test_nothrow highlight(print)


    @test_nothrow highlight_syntax("""
This is ::Int64 my style
""") == "This is \e[1m\e[38;2;252;98;98m::\e[22m\e[39mInt64 my style\n"

    @test_nothrow highlight_syntax("""
This is ::Int64 my style
print(x + 2)
""") == "This is \e[1m\e[38;2;252;98;98m::\e[22m\e[39mInt64 my style\n\e[1m\e[38;2;255;245;157mprint\e[22m\e[39m\e[38;2;252;116;116m(\e[39mx \e[1m\e[38;2;252;98;98m+\e[22m\e[39m \e[38;2;144;202;249m2\e[39m\e[38;2;252;116;116m)\e[39m\n"

    @test_nothrow load_code_and_highlight("14_test_highlight.jl", 7)


end

