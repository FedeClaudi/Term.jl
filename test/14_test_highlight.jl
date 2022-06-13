import Term: load_code_and_highlight, highlight_syntax, highlight, theme

@testset "\e[34mHIGHLIGHT" begin
    @test highlight("test 1 123 33.4 44,5 +1 -2 12 0.5, ,, ...") ==
          "test \e[38;2;144;202;249m1\e[39m \e[38;2;144;202;249m123\e[39m \e[38;2;144;202;249m33.4\e[39m \e[38;2;144;202;249m44\e[39m,\e[38;2;144;202;249m5\e[39m \e[38;2;239;83;80m+\e[39m\e[38;2;144;202;249m1\e[39m \e[38;2;239;83;80m-\e[39m\e[38;2;144;202;249m2\e[39m \e[38;2;144;202;249m12\e[39m \e[38;2;144;202;249m0.5\e[39m, ,, ..."

    @test highlight("this is ::Int64") == "this is \e[38;2;206;147;216m::Int64\e[39m"

    @test highlight("print", :func) == "\e[38;2;255;238;88mprint\e[39m"

    @test highlight("1 + 2", :code) == "\e[3m\e[38;2;255;238;88m1 + 2\e[23m\e[39m"

    @test highlight("this 1 + `test`") ==
          "this \e[38;2;144;202;249m1\e[39m \e[38;2;239;83;80m+\e[39m \e[3m\e[38;2;255;238;88m`test`\e[23m\e[39m"

    @test highlight(1) == "\e[38;2;144;202;249m1\e[39m"

    @test highlight([1, 2, 3]) == "\e[38;2;144;202;249m[1, 2, 3]\e[39m"

    @test highlight(Int32) == "\e[38;2;206;147;216mInt32\e[39m"

    @test highlight(print) == "\e[38;2;255;238;88mprint\e[39m"

    @test highlight("this :this :(x+y) 'a'") ==
          "this \e[38;2;255;167;38m:this\e[39m \e[38;2;255;202;40m:\e[38;2;255;245;157m(\e[39m\e[38;2;255;202;40mx\e[38;2;239;83;80m+\e[39m\e[38;2;255;202;40my\e[38;2;255;245;157m)\e[39m\e[38;2;255;202;40m\e[39m \e[38;2;100;181;101m'\e[39ma\e[38;2;100;181;101m'\e[39m"

    @test highlight(:x) == "\e[38;2;255;167;38mx\e[39m"

    @test highlight(:(x + y)) == "\e[38;2;255;202;40mx + y\e[39m"

    @test highlight_syntax("""
    This is ::Int64 my style
    print(x + 2)
    """) ==
          "\e[38;2;222;222;222mThis\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;222;222mis\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;109;89m::\e[39m\e[38;2;222;222;222mInt64\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;222;222mmy\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;222;222mstyle\e[39m\e[38;2;222;222;222m\n\e[39m\e[38;2;232;212;114mprint\e[39m\e[38;2;227;136;100m(\e[39m\e[38;2;222;222;222mx\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;109;89m+\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;144;202;249m2\e[39m\e[38;2;227;136;100m)\e[39m\e[38;2;222;222;222m\n\e[39m"

    @test load_code_and_highlight("02_test_ansi.jl", 7)[1:100] ==
          "{red bold}❯{/red bold} {white}7{/white}     get_color,\n  {grey39}8{/grey39}     NamedColor,\n  {gre"
    # end
end
