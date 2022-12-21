import Term:
    load_code_and_highlight, highlight_syntax, highlight, reshape_code_string, str_trunc
import Term.Style: apply_style

@testset "\e[34mHIGHLIGHT" begin
    @test highlight("test 1 123 33.4 44,5 +1 -2 12 0.5, ,, ...") ==
          "test {#90CAF9}1{/#90CAF9} {#90CAF9}123{/#90CAF9} {#90CAF9}33.4{/#90CAF9} {#90CAF9}44{/#90CAF9},{#90CAF9}5{/#90CAF9} {#EF5350}+{/#EF5350}{#90CAF9}1{/#90CAF9} {#EF5350}-{/#EF5350}{#90CAF9}2{/#90CAF9} {#90CAF9}12{/#90CAF9} {#90CAF9}0.5{/#90CAF9}, ,, ..."

    @test highlight("this is ::Int64";) == "this is {#CE93D8}::Int64{/#CE93D8}"

    @test highlight("print", :func;) == "\e[38;2;242;215;119mprint\e[39m"

    @test highlight("1 + 2", :code;) == "\e[38;2;255;238;88m1 + 2\e[39m"

    @test highlight("this 1 + `test`") ==
          "this {#90CAF9}1{/#90CAF9} {#EF5350}+{/#EF5350} {#FFEE58}`test`{/#FFEE58}"

    @test highlight(1;) == "\e[38;2;144;202;249m1\e[39m"

    @test highlight([1, 2, 3];) == "\e[38;2;144;202;249m[1, 2, 3]\e[39m"

    @test highlight(Int32;) == "\e[38;2;206;147;216mInt32\e[39m"

    @test highlight(print;) == "\e[38;2;242;215;119mprint\e[39m"

    @test highlight("this :this :(x+y) 'a'";) ==
          "this {#FFA726}:this{/#FFA726} {#FFCA28}:(x{#EF5350}+{/#EF5350}y){/#FFCA28} {#64b565}'a'{/#64b565}"

    @test highlight(:x;) == "\e[38;2;255;167;38mx\e[39m"

    @test highlight(:(x + y);) == "\e[38;2;255;202;40mx + y\e[39m"
end

@testset "HIGHLIGHT syntax basic" begin
    @test highlight_syntax("""
    This is ::Int64 my style
    print(x + 2)
    """) ==
          "\e[38;2;222;222;222mThis\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;222;222mis\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;109;89m::\e[39m\e[38;2;222;222;222mInt64\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;222;222mmy\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;222;222mstyle\e[39m\e[38;2;222;222;222m\n\e[39m\e[38;2;232;212;114mprint\e[39m\e[38;2;227;136;100m(\e[39m\e[38;2;222;222;222mx\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;222;109;89m+\e[39m\e[38;2;222;222;222m \e[39m\e[38;2;144;202;249m2\e[39m\e[38;2;227;136;100m)\e[39m\e[38;2;222;222;222m\n\e[39m"

    @test load_code_and_highlight("02_test_ansi.jl", 7)[1:100] ==
          "  {grey39}4{/grey39} \e[38;2;222;222;222m    \e[39m\e[38;2;222;222;222mis_hex_color\e[39m\e[38;2;227;136;"

    @test load_code_and_highlight("02_test_ansi.jl", 1)[1:100] ==
          "{red bold}❯{/red bold} {white}1{/white} \e[38;2;122;147;245mimport\e[39m\e[38;2;222;222;222m \e[39m\e[3"

    @test load_code_and_highlight("02_test_ansi.jl", 94)[1:100] ==
          "  {grey39}91{/grey39} \e[38;2;222;222;222m        \e[39m\e[38;2;222;222;222m@test\e[39m\e[38;2;222;222;22"

    @test load_code_and_highlight("02_test_ansi.jl", 92)[1:100] ==
          "  {grey39}89{/grey39} \e[38;2;222;222;222m    \e[39m\e[38;2;222;222;222mhexes\e[39m\e[38;2;222;222;222m \e"
end

@testset "HIGHLIGHT syntax adv" begin
    for (i, ln) in enumerate((1, 2, 5, 90, 93, 94))
        for (j, δ) in enumerate((0, 1, 3, 5))
            _code = load_code_and_highlight("02_test_ansi.jl", ln; δ = δ)
            IS_WIN || @compare_to_string(_code, "code_highlight_$(i)_$(j)")

            for (k, w) in enumerate((15, 33, 67))
                _code_w = reshape_code_string(_code, w)
                IS_WIN || @compare_to_string(_code_w, "code_highlight_$(i)_$(j)_$(k)")

                _code_s = str_trunc(apply_style(_code), w; ignore_markup = true)
                IS_WIN || @compare_to_string(_code_s, "code_highlight_$(i)_$(j)_$(k)_trunc")
            end
        end
    end
end
