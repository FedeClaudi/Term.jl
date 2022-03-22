import Term.markup: has_markup, extract_markup
import Term.style: apply_style
import Term: tprint
import Term: Panel, RenderableText

@testset "\e[34mMarkup - detection" begin
    # with no markup
    strings = [
        "asdasdasdsad",
        "asdasda[asdasdasd",
        "asdasdad[[asdasdasdas]]asdasd",
        "sadas[asdasdasd\nasdsadassadsa[[asdsadas]]asdsdadas",
    ]

    for str in strings
        @test has_markup(str) == false
        @test length(extract_markup(str)) == 0
    end

    # with markup
    function ntags(tag)
        return if length(tag.inner_tags) > 0
            length(tag.inner_tags) + sum(ntags.(tag.inner_tags))
        else
            0
        end
    end
    tottags(tags) = length(tags) + sum(ntags.(tags))

    strings = [
        ("[red]asdasdsa[/red]", 1),
        ("[red]dasdasdsa[green]asdasda[/green]asdasdasp[/red]", 2),
        ("[blue]onasdasdsa[green]asdasdasp[bold]asdasda", 3),
    ]

    for (str, n) in strings
        @test has_markup(str) == true
        @test tottags(extract_markup(str)) == n
    end
end




@testset "\e34mStyle" begin
    @test apply_style("test") == "test"

    @test apply_style("[red]test[/red]") == "\e[31mtest\e[39m"

    @test apply_style("[red]te[blue on_green]s[/blue on_green]t[/red]") == "\e[31mte\e[39m\e[42m\e[34ms\e[49m\e[39m\e[31mt\e[39m"

    @test apply_style("[red]\ntest[bold] sdfsfsd[/bold]sdfsdf") == "\e[31m\ntest\e[39m\e[1m sdfsfsd\e[22m\e[31msdfsdf\e[39m"

    @test apply_style("""
    test [red] sdfsdf
    fdsf[/red] [bold] sfsdfp[green] sdfsdp[/green]sdsdfs
    pdfsdp[/bold]""") == "test \e[31m sdfsdf\nfdsf\e[39m \e[1m sfsdfp\e[22m\e[32m sdfsdp\e[39m\e[1msdsdfs\npdfsdp\e[22m"

end


@testset "\e34mTprint" begin
    stprint(x) = chomp(sprint(tprint, x; context=stdout))

    # ------------------------------- with strings ------------------------------- #
    @test stprint("test") == "test"

    @test stprint("[red]test[/red]") == "\e[31mtest\e[39m"

    @test stprint("[red]te[blue on_green]s[/blue on_green]t[/red]") == "\e[31mte\e[39m\e[42m\e[34ms\e[49m\e[39m\e[31mt\e[39m"

    @test stprint("[red]\ntest[bold] sdfsfsd[/bold]sdfsdf") == "\e[31m\ntest\e[39m\e[1m sdfsfsd\e[22m\e[31msdfsdf\e[39m"

    @test stprint("""
    test [red] sdfsdf
    fdsf[/red] [bold] sfsdfp[green] sdfsdp[/green]sdsdfs
    pdfsdp[/bold]""") == "test \e[31m sdfsdf\nfdsf\e[39m \e[1m sfsdfp\e[22m\e[32m sdfsdp\e[39m\e[1msdsdfs\npdfsdp\e[22m"

    @test_nothrow tprint(Panel("test"; style="red"))

end