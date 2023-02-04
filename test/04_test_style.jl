import Term.Style: apply_style
import Term: tprint, tprintln, get_file_format, reshape_text

@testset "\e[34mStyle\e[0m" begin
    @test apply_style("test") == "test"

    @test apply_style("{red}test{/red}") == "\e[31mtest\e[39m"

    @test apply_style("{red}te{blue on_green}s{/blue on_green}t{/red}") ==
          "\e[31mte\e[34m\e[42ms\e[39m\e[49m\e[31mt\e[39m"

    @test apply_style("{red}\ntest{bold} sdfsfsd{/bold}sdfsdf{/red}") ==
          "\e[31m\ntest\e[1m sdfsfsd\e[22m\e[31msdfsdf\e[39m"

    @test apply_style("""
    test {red} sdfsdf
    fdsf{/red} {bold} sfsdfp{green} sdfsdp{/green}sdsdfs
    pdfsdp{/bold}""") ==
          "test \e[31m sdfsdf\nfdsf\e[39m \e[1m sfsdfp\e[32m sdfsdp\e[39msdsdfs\npdfsdp\e[22m"

    # check that parentheses are escaped correctly
    @test apply_style("This and that {{something}} for") ==
          "This and that {{something}} for"
end

@testset "Style with nested tags" begin
    txt = "{red}adasd ad sa dsa{green} ad {blue} sd d ads ad {/blue}da dad {/green} asdsa dad a {/red}"
    @test apply_style(txt) ==
          "\e[31madasd ad sa dsa\e[32m ad \e[34m sd d ads ad \e[39m\e[32mda dad \e[39m\e[31m asdsa dad a \e[39m"

    txt = "{red}adasd ad sa dsa{bold} ad {blue} sd d ads ad {/blue}da dad {/bold} asdsa dad a {/red}"
    @test apply_style(txt) ==
          "\e[31madasd ad sa dsa\e[1m ad \e[34m sd d ads ad \e[39m\e[31mda dad \e[22m\e[31m asdsa dad a \e[39m"

    txt = "{red}adasd ad sa dsa{green} ad {blue} sd d ads ad da dad {/green} asdsa ddfsf {/blue}ad a {/red}"
    @test apply_style(txt) ==
          "\e[31madasd ad sa dsa\e[32m ad \e[34m sd d ads ad da dad \e[39m\e[31m asdsa ddfsf \e[39mad a \e[39m"

    txt = "{on_red}adasd ad sa dsa{green} ad {on_black} sd d ads ad da{/on_black} dad {/green} asdsa ddfsf ad a {/on_red}"
    @test apply_style(txt) ==
          "\e[41madasd ad sa dsa\e[32m ad \e[40m sd d ads ad da\e[49m\e[32m\e[41m dad \e[39m\e[41m asdsa ddfsf ad a \e[49m"

    txt = "{on_(25, 25, 25)}adasd ad sa dsa{green} ad {on_black} sd d ads ad da{/on_black} {white}dad{/white} asad {/green} asdsa ddfsf ad a {/on_(25, 25, 25)}"
    @test apply_style(txt) ==
          "\e[48;2;25;25;25madasd ad sa dsa\e[32m ad \e[40m sd d ads ad da\e[49m\e[32m\e[48;2;25;25;25m \e[37mdad\e[39m\e[32m asad \e[39m\e[48;2;25;25;25m asdsa ddfsf ad a \e[49m"

    txt = "{(220, 180, 150)} pink {bold}pink bold {dodger_blue2} pink bold blue {/dodger_blue2} pink bold {/bold} pink {on_(25, 55, 100)} pink on blue {/(220, 180, 150)} just on blue {/on_(25, 55, 100)} NOW SIMPLE WHITE {red} red red red {/red} white white {underline} underline underline {/underline}"
    @test apply_style(txt) ==
          "\e[38;2;220;180;150m pink \e[1mpink bold \e[38;5;27m pink bold blue \e[39m\e[38;2;220;180;150m pink bold \e[22m\e[38;2;220;180;150m pink \e[48;2;25;55;100m pink on blue \e[39m just on blue \e[49m NOW SIMPLE WHITE \e[31m red red red \e[39m white white \e[4m underline underline \e[24m"
end

@testset "Style with nested tags and reshaping" begin
    txts = [
        "{red}adasd ad sa dsa{green} ad {blue} sd d ads ad {/blue}da dad {/green} asdsa dad a {/red}",
        "{red}adasd ad sa dsa{bold} ad {blue} sd d ads ad {/blue}da dad {/bold} asdsa dad a {/red}",
        "{red}adasd ad sa dsa{green} ad {blue} sd d ads ad da dad {/green} asdsa ddfsf {/blue}ad a {/red}",
        "{on_red}adasd ad sa dsa{green} ad {on_black} sd d ads ad da{/on_black} dad {/green} asdsa ddfsf ad a {/on_red}",
        "{on_(25, 25, 25)}adasd ad sa dsa{green} ad {on_black} sd d ads ad da{/on_black} {white}dad{/white} asad {/green} asdsa ddfsf ad a {/on_(25, 25, 25)}",
        "{(220, 180, 150)} pink {bold}pink bold {dodger_blue2} pink bold blue {/dodger_blue2} pink bold {/bold} pink {on_(25, 55, 100)} pink on blue {/(220, 180, 150)} just on blue {/on_(25, 55, 100)} NOW SIMPLE WHITE {red} red red red {/red} white white {underline} underline underline {/underline}",
    ]

    sizes = (25, 33, 61)

    for (i, txt) in enumerate(txts)
        for (j, w) in enumerate(sizes)
            IS_WIN ||
                @compare_to_string apply_style(reshape_text(txt, w)) "nested_tags_reshape_$(i)_$(j)"
            IS_WIN ||
                @compare_to_string reshape_text(apply_style(txt), w) "nested_tags_reshape_$(i)_$(j)_reverse"
        end
    end
end

@testset "\e[34mTprint\e[0m" begin
    stprint(x) = chomp(sprint(tprint, x; context = stdout))
    stprintln(x) = chomp(sprint(tprintln, x; context = stdout))

    # ------------------------------- with strings ------------------------------- #
    @test stprint("test") == "test"
    # @test stprintln("test") == "test "

    @test stprint("{red}test{/red}") == "\e[31mtest\e[39m"
    # @test stprintln("{red}test{/red}") == "\e[31mtest\e[39m "

    @test stprint("{red}te{blue on_green}s{/blue on_green}t{/red}") ==
          "\e[31mte\e[34m\e[42ms\e[39m\e[49m\e[31mt\e[39m"
    # @test stprintln("{red}te{blue on_green}s{/blue on_green}t{/red}") == "\e[31mte\e[34m\e[42ms\e[39m\e[49m\e[31mt\e[39m "

    @test stprint("{red}\ntest{bold} sdfsfsd{/bold}sdfsdf{/red}") ==
          "\e[31m\ntest\e[1m sdfsfsd\e[22m\e[31msdfsdf\e[39m"
    # @test stprintln("{red}\ntest{bold} sdfsfsd{/bold}sdfsdf{/red}") == "\e[31m\ntest\e[1m sdfsfsd\e[22m\e[31msdfsdf\e[39m "

    @test stprint("""
    test {red} sdfsdf
    fdsf{/red} {bold} sfsdfp{green} sdfsdp{/green}sdsdfs
    pdfsdp{/bold}""") ==
          "test \e[31m sdfsdf\nfdsf\e[39m \e[1m sfsdfp\e[32m sdfsdp\e[39msdsdfs\npdfsdp\e[22m"

    @test stprint("This and that {{something}} for") == "This and that {{something}} for"
end

@testset "\e[34mTmisc\e[0m" begin
    @test get_file_format(1024) == "1.0 KB"
    @test get_file_format(10243312) == "9.77 MB"
end
