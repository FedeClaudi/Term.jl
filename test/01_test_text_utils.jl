import Term: remove_markup,
        has_markup,
        remove_ansi,
        has_ansi,
        get_last_ANSI_code,
        cleantext,
        textlen,
        escape_brackets,
        unescape_brackets,
        replace_text,
        nospaces,
        remove_brackets,
        unspace_commas,
        chars,
        join_lines,
        split_lines,
        textwidth,
        fillin, 
        truncate,
        reshape_text

@testset "TU_markup" begin
        strings = [
            ("this is [red] some [blue] text [/blue] that I like[/red]",
                "this is  some  text  that I like",
            ), (
                "[bold underline] this is [red on_green] text [/red on_green] I like [/bold underline]",
                " this is  text  I like ",
            )
        ]

        for (s1, s2) in strings
            @test has_markup(s1) == true
            @test remove_markup(s1) == s2
            @test cleantext(s1) == s2
            @test textlen(s1) == textwidth(s2)
        end
end

@testset "TU_ansi" begin
    strings = [
        (
            "this is \e[31m some \e[34m text \e[39m\e[31m that I like\e[39m",
            "this is  some  text  that I like",
            "\e[39m"
        ), (
            "\e[1m\e[4m this is \e[31m\e[42m text \e[39m\e[49m\e[4m I like \e[22m\e[24m",
            " this is  text  I like ",
            "\e[24m"
        )
    ]

    for (s1, s2, ltag) in strings
        @test has_ansi(s1) == true
        @test remove_ansi(s1) == s2
        @test get_last_ANSI_code(s1) == ltag
    end
end


@testset "TU_brackets" begin
    strings = [
        ("test [vec] nn", "test [[vec]] nn"),
        ("[1, 2, 3]", "[[1, 2, 3]]")
    ]

    for (s1, s2) in strings
        escaped = escape_brackets(s1)
        @test escaped == s2
        @test unescape_brackets(escaped) == s1
        @test unescape_brackets(s1) == s1
    end
end

@testset "TU_replace_text" begin
    text = "abcdefghilmnopqrstuvz"

    @test replace_text(text, 1, 5, "aaa") == "aaafghilmnopqrstuvz"
    @test replace_text(text, 1, 5, ',') ==  ",,,,fghilmnopqrstuvz"

    @test replace_text(text, 18, 21, "aaa") == "abcdefghilmnopqrstaaa"
    @test replace_text(text, 18, 21, ',') ==  "abcdefghilmnopqrst,,,"

    @test replace_text(text, 10, 15, "aaa") == "abcdefghilaaarstuvz"
    @test replace_text(text, 10, 15, ',') ==  "abcdefghil,,,,,rstuvz"

    @test nospaces("a (1, 2, 3) 4") == "a(1,2,3)4"
    @test remove_brackets("aaa (asdsd) BB") == "aaa asdsd BB"


    @test unspace_commas("a, 2, 3") == "a,2,3"
end

@testset "TU_misc" begin
    @test chars("abcd") == ['a', 'b', 'c', 'd']


    strings = [
        "aaa\nadasda\nasdasda",
        """
        asdasd
adsada
asddsa"""
    ]
    for str in strings
        @test join_lines(split_lines(str)) == str
    end
end

@testset "TU_reshape" begin
    strings = ["""
    asdasas sadasd
asadasd asdasdasdas """, """
sdssd asdasdasda sdasdasdasdaska sbjhwbfwkbgaerfwf
asdasd asdasdasd asdasdaswefafwfw fwefewafw
asdasdas """, """

asdasdasdasdas
asdasd asdasda sdsdfasdfasd adsfsadfsd agaegefgcwefawe fawefawesfc waszdvearsdfv dsfasdfsd
""", 
""" [red] adsbiadiasd asiudha asuydba basdi [/red] ad
in this case [red on_green] blefiw [blue] kaduasdna [/blue] ashidasda 
sadadand [/red on_green]"""
]

    for str in strings
        @test same_widths(fillin(str)) == true
        @test textwidth(truncate(str, 10)) <= 10

        check_widths(reshape_text(str, 10), 11)
        check_widths(reshape_text(str, 21), 22)
        check_widths(reshape_text(str, 25), 26)

    end

end