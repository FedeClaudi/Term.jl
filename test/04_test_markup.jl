import Term.markup: has_markup, extract_markup


@testset "Markup - detection" begin
    # with no markup
    strings = [
        "asdasdasdsad",
        "asdasda[asdasdasd",
        "asdasdad[[asdasdasdas]]asdasd",
        "sadas[asdasdasd\nasdsadassadsa[[asdsadas]]asdsdadas"
    ]

    for str in strings
        @test has_markup(str) == false
        @test length(extract_markup(str)) == 0
    end


    # with markup
    ntags(tag) = length(tag.inner_tags) > 0 ? length(tag.inner_tags) + sum(ntags.(tag.inner_tags)) : 0
    tottags(tags) = length(tags) + sum(ntags.(tags))

    strings = [
        ("[red]asdasdsa[/red]", 1),
        ("[red]dasdasdsa[green]asdasda[/green]asdasdasp[/red]", 2),
        ("[blue]onasdasdsa[green]asdasdasp[bold]asdasda", 3)
    ]

    for (str, n) in strings
        @test has_markup(str) == true
        @test tottags(extract_markup(str)) == n
    end

end