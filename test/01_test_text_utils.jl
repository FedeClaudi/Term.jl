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
import Term.style: apply_style

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

        @test remove_markup("text with [[double]] squares") == "text with [[double]] squares"
        @test has_markup("text with [[double]] squares") == false
end

@testset "TU_ansi" begin
    apply_style("test[(.2, .5, .6)]coloooor[/(.2, .5, .6)]")
    strings = [
        (
            "this is \e[31m some \e[34m text \e[39m\e[31m that I like\e[39m",
            "this is  some  text  that I like",
            "\e[39m"
        ), (
            "\e[1m\e[4m this is \e[31m\e[42m text \e[39m\e[49m\e[4m I like \e[22m\e[24m",
            " this is  text  I like ",
            "\e[24m"
        ), (
            "test\e[38;2;51;128;153mcoloooor\e[39m and white",
            "testcoloooor and white",
            "\e[39m"
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

    @test replace_text(text, 0, 5, "aaa") == "aaafghilmnopqrstuvz"
    @test replace_text(text, 0, 5, ',') ==  ",,,,,fghilmnopqrstuvz"

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
    str =     """
    Lorem ipsum [bold]dolor sit[/bold] amet, consectetur adipiscing elit,
    ed do e[red]iusmod tempor incididunt[/red] ut [bold]labore et [underline]dolore[/underline] magna aliqua.[/bold] Ut enim ad minim
    veniam, quis[green] nostrud exercitation [on_black]ullamco laboris nisi ut aliquip ex [/on_black]
    ea commodo consequat.[blue] Duis aute irure dolor in[/blue] reprehenderit 
    in voluptate velit[/green] esse [italic]cillum dolore[/italic][red] eu[/red][italic green] fugiat [/italic green]nulla 
    pariatur. Excepteur[red] sint[/red][blue] occaecat cupidatat [/blue]non proident, 
    sunt in culpa qui [italic]officia[/italic] deserunt mollit anim 
    id est laborum."""

    str_reshaped = "Lorem ipsum \e[1mdolor sit\e[22m amet, conse\e[0m\nctetur adipiscing elit,\e[0m\ned do e\e[31miusmod tempor incididunt\e[39m\e[0m\nut \e[1mlabore et \e[4mdolore\e[24m\e[1m magna aliqua\e[0m\n\e[1m\e[1m. Ut enim ad minim\e[0m\nveniam, quis\e[32m nostrud exercitation\e[0m\n\e[32m\e[40mullamco laboris nisi ut aliquip\e[0m\n\e[32m\e[40mex \e[49m\e[0m\nea commodo consequat.\e[34m Duis aute\e[0m\n\e[34mirure dolor in\e[39m reprehenderit\e[0m\nin voluptate velit[/green] esse \e[3mc\e[0m\n\e[3millum dolore\e[23m\e[31m eu\e[39m\e[23m\e[3m\e[32m fugiat nulla\e[0m\npariatur. Excepteur\e[31m sint\e[39m\e[34m occaecat\e[0m\n\e[34mcupidatat \e[39mnon proident,\e[0m\nsunt in culpa qui \e[3mofficia\e[23m deserun\e[0m\nt mollit anim\e[0m\nid est laborum."


    strings = [
        (
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            "Lorem ipsum dolor sit amet, conse\nctetur adipiscing elit, sed do\neiusmod tempor incididunt ut\nlabore et dolore magna aliqua."
        ), (
            "Lorem [red]ipsum dolor sit [underline]amet, consectetur[/underline] adipiscing elit, [/red][blue]sed do eiusmod tempor incididunt[/blue] ut labore et dolore magna aliqua.",
            "Lorem \e[31mipsum dolor sit \e[4mamet, conse\e[0m\n\e[31m\e[4mctetur\e[24m\e[31m adipiscing elit, \e[39m\e[34msed do\e[0m\n\e[31m\e[34meiusmod tempor incididunt\e[39m ut\e[0m\n\e[31mlabore et dolore magna aliqua.\e[0m"
        ), (
            "Lorem[red]ipsumdolorsit[underline]amet, consectetur[/underline] adipiscing elit, [/red]seddoeiusmo[blue]dtemporincididunt[/blue]ut labore et dolore magna aliqua.",
            "Lorem\e[31mipsumdolorsit\e[4mamet, consectet\e[0m\n\e[31m\e[4mur\e[24m\e[31m adipiscing elit, \e[39mseddoeiusmo\e[34mdt\e[0m\n\e[31m\e[34memporincididunt\e[39mut labore et dolor\e[0m\n\e[31me magna aliqua.\e[0m"
        ), (
            "ต้าอ่วยวาทกรรมอาว์เซี้ยว กระดี๊กระด๊า ช็อปซาดิสต์โมจิดีพาร์ตเมนต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
            "ต้าอ่วยวาทกรรมอาว์เซี้ยว กระดี๊กระด๊า\nช็อปซาดิสต์โมจิดีพาร์ตเมนต์ อินดอร์วิว สี่แย\nกมาร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน ยาวีแพลนห\nงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุม\nบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เ\nฟอร์รี่บึมมาราธอน"
        ), (
            "ต้าอ่วยวาท[red]กรรมอาว์เซี้ยว กระดี๊กระด๊า [/red]ช็อปซาดิสต์โมจิดีพาร์ตเม[blue underline]นต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเต[/blue underline]อร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
            "ต้าอ่วยวาท\e[31mกรรมอาว์เซี้ยว กระดี๊กระด๊า \e[39mช็อป\e[0m\nซาดิสต์โมจิดีพาร์ตเม\e[4m\e[34mนต์ อินดอร์วิว สี่แยกมา\e[0m\n\e[4m\e[34mร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน ยาวีแพลนหงวน\e[0m\n\e[4m\e[34mสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า\e[0m\n\e[4m\e[34mบอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์\e[0m\n\e[4m\e[34mรี่บึมมาราธอน\e[0m"
        ), (
            "국가유공자·상이군경 및 전몰군경의 유가족은 법률이 정하는 바에 의하여",
            "국가유공자·상이군경 및 전몰군경의\n유가족은 법률이 정하는 바에\n의하여"
        ), (
            "국[red]가유공자·상이군[bold]경 및 전[/bold]몰군경의 유[/red]가족은 법률이 정하는 바에 의하여",
            "국\e[31m가유공자·상이군\e[1m경 및 전\e[22m\e[31m몰군경의\e[0m\n\e[31m\e[31m유\e[39m가족은 법률이 정하는 바에\e[0m\n\e[31m의하여\e[0m"
        ), (
            "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────",
            "┌────────────────┬───────────────\n─┬────────────────┬──────────────\n──┬──────────────"
        ), (
            "┌────────────abcde────┬──────────── ────┬────────abcde fghi────────┬────────────────┬──────────────",
            "┌────────────abcde────┬──────────\n── ────┬────────abcde fghi───────\n─┬────────────────┬──────────────"
        ), (
            "┌─────────[red]───ab[/red]cde────┬──────[green]────── ────┬────────abcde fghi[/green]────────┬────────────────┬──────────────",
            "┌─────────\e[31m───ab\e[39mcde────┬──────\e[32m────\e[0m\n\e[32m── ────┬────────abcde fghi\e[39m───────\e[0m\n─┬────────────────┬──────────────\e[0m\n\e[0m"
        ), (
            "┌──────────[red]────[/red]──┬[blue bold]────────────────┬──[/blue bold]──────────────┬────────────────┬──────────────end",
            "┌──────────\e[31m────\e[39m──┬\e[1m\e[34m───────────────\e[0m\n\e[1m\e[34m─┬────────────────┬──────────────\e[0m\n\e[1m\e[34m──┬──────────────end\e[0m"
        ), (
            "."^100  ,
            ".................................\n.................................\n.................................\n."
        ), (
            ".[red]|||[/red]...."^10,
            ".\e[31m|||\e[39m.....\e[31m|||\e[39m.....\e[31m|||\e[39m.....\e[31m|||\e[39m....\e[0m\n.\e[31m|||\e[39m.....\e[31m|||\e[39m.....\e[31m|||\e[39m.....\e[31m|||\e[39m.....\e[31m\e[0m\n\e[31m|||\e[39m.....\e[31m|||\e[39m....\e[0m"
        ), (
            ".|||...."^10,
            ".|||.....|||.....|||.....|||.....\n|||.....|||.....|||.....|||.....|\n||.....|||...."
        ), (
            str, 
            str_reshaped
        )
    ]

    for (s1, s2) in strings
        reshaped = reshape_text(s1, 33)
        @test reshaped == s2
    end


    for width in 33:100
        rh = reshape_text(str, width)
        @test any(textlen.(split(rh, "\n")) .> width) == false
    end
end