import Term: load_code_and_highlight, highlight_syntax, highlight, theme


@testset "\e[34mHIGHLIGHT" begin

    @test highlight("this is 1 12") == "this is[#90CAF9] 1 [/#90CAF9]12"

    @test highlight("this is ::Int64") == "this is [#d880e7]::Int64[/#d880e7]"

    @test highlight("print", :func) == "[#fff126]print[/#fff126]"

    @test highlight("1 + 2", :code) == "[#ffd77a]1 + 2[/#ffd77a]"

    @test highlight("this 1 + `test`") == "this[#90CAF9] 1 [/#90CAF9]+ [#ffd77a]`test`[/#ffd77a]"

    @test highlight_syntax("""
This is ::Int64 my style
""") == "This is \e[1m\e[38;2;252;98;98m::\e[22m\e[39mInt64 my style\n"

    @test highlight_syntax("""
This is ::Int64 my style
print(x + 2)
""") == "This is \e[1m\e[38;2;252;98;98m::\e[22m\e[39mInt64 my style\n\e[1m\e[38;2;255;245;157mprint\e[22m\e[39m\e[38;2;252;116;116m(\e[39mx \e[1m\e[38;2;252;98;98m+\e[22m\e[39m \e[38;2;144;202;249m2\e[39m\e[38;2;252;116;116m)\e[39m\n"

    @test_nowarn load_code_and_highlight("14_test_highlight.jl", 7)


end

