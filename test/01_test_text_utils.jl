import Term: remove_markup, remove_ansi, truncate, reshape_text
import Term.style: apply_style

@testset "\e[31mTU - remove" begin
    # ------------------------------- remove markup ------------------------------ #
    @test remove_markup("[red]text[/red]") == "text"
    @test remove_markup("[red]sffsdf[green on_blue italic]") == "sffsdf"
    @test remove_markup("[red]aa[green on_blue italic]bb[/green on_blue italic]cc[/]") ==
          "aabbcc"
    @test remove_markup("[(255, 1, 3)]aa[#ff0022 italic]bb[/ff0022]") == "aabb"

    # test that parentheses are ignored
    strings = [
        "1111",
        "[222a",
        "333asd[adsada",
        "a444asdas]asda]asda",
        "[a5555adsad[[sada",
        "a6666[[asdasd]]",
    ]
    for str in strings
        @test remove_markup(str) == str
    end


    # -------------------------------- remove ansi ------------------------------- #
    strings = [
        ("[red]asdasdad[/red]", "asdasdad"),
        ("aaa[bold on_green]bb[/]", "aaabb"),
        ("[red]aa[bold]bb[#ffffff]cc[/#ffffff]dd", "aabbccdd"),
        ("[bold italic underline]aa[/bold italic underline]", "aa"),
    ]
    for (str, clean) in strings
        @test remove_ansi(apply_style(str)) == clean
        @test remove_markup(str) == clean
    end
end


@testset "\e[31mTU - reshape text" begin
    nlines(x) = length(split(x, "\n"))
    lw(x) = length(split(x, "\n")[1])

    # --------------------------------- truncate --------------------------------- #
    strings = [("a"^20, 6), ("asd"^33, 12), ("c"^3, 22)]
    for (str, w) in strings
        @test length(truncate(str, w)) <= w
    end


    # ---------------------------------- reshape --------------------------------- #
    s1 = "."^500

    sizes = [(50, 10), (25, 20), (5, 100), (100, 5)]

    for (w, h) in sizes
        rs = reshape_text(s1, w)
        @test lw(rs) == w
        @test nlines(rs) == h
    end


    s1 = "[red]aa[green]bb[/green]c[/red]"^100

    sizes = [(50, 10), (25, 20), (5, 100), (100, 5)]

    for (w, h) in sizes
        rs = remove_markup(reshape_text(s1, w))
        @test lw(rs) == w
        @test nlines(rs) == h
    end

end
