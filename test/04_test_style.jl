import Term.Style: apply_style
import Term: tprint, tprintln

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
        "test \e[31m sdfsdf\nfdsf\e[39m \e[1m sfsdfp\e[32m sdfsdp\e[39m\e[1msdsdfs\npdfsdp\e[22m\e[39m"

    # check that parentheses are escaped correctly
    @test apply_style("This and that {{something}} for") ==
        "This and that {{something}} for"
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
        "test \e[31m sdfsdf\nfdsf\e[39m \e[1m sfsdfp\e[32m sdfsdp\e[39m\e[1msdsdfs\npdfsdp\e[22m\e[39m"

    @test stprint("This and that {{something}} for") == "This and that {{something}} for"
end
