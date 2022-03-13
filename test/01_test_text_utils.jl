import Term: remove_markup, remove_ansi, truncate, reshape_text, textlen
import Term.style: apply_style

@testset "\e[34mTU - remove" begin
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

@testset "\e[34mTU - reshape text" begin




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

    for L in (25, 50, 125)
        lorem = "Lorem ipsum dolor sit amet, [red]consectetur adipiscing elit, sed do[blue] eiusmod tempor[/blue] incididunt ut labore et [/red]dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        r1 = reshape_text(lorem, L)
        for line in split(r1, "\n")
            @test textlen(line) == L
        end
    end
end
