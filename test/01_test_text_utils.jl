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


    strings = [
        (
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            "Lorem ipsum dolor sit\namet, consectetur \nadipiscing elit, sed \ndo eiusmod tempor \nincididunt ut labore \net dolore magna \naliqua."
        ), (
            "Lorem [red]ipsum dolor sit [underline]amet, consectetur[/underline] adipiscing elit, [/red][blue]sed do eiusmod tempor incididunt[/blue] ut labore et dolore magna aliqua.",
            "Lorem \e[31mipsum dolor sit\e[0m\n\e[31ma\e[4mmet, consectetur\e[24m\e[31m \e[0m\n\e[4m\e[24m\e[31madipiscing elit, \e[39m\e[34msed \e[0m\n\e[39m\e[34mdo eiusmod tempor \e[0m\nincididunt\e[39m ut labore \e[0m\n\e[39met dolore magna \e[0m\naliqua.\e[0m"
        ), (
            "Lorem[red]ipsumdolorsit[underline]amet, consectetur[/underline] adipiscing elit, [/red]seddoeiusmo[blue]dtemporincididunt[/blue]ut labore et dolore magna aliqua.",
            "Lorem\e[31mipsumdolorsit\e[4mame\e[0m\n\e[31m\e[4mt, consectetur\e[24m\e[31m \e[0m\n\e[24m\e[31madipiscing elit, \e[39m\e[0m\n\e[39mseddoeiusmo\e[34mdtemporinc\e[0m\n\e[34mididunt\e[39mut labore et \e[0m\n\e[39mdolore magna \e[0m\naliqua.\e[0m"
        ), (
            "استنكار  النشوة وتمجيد الألم نشأت بالفعل، وسأعرض لك",
            "استنكار  النشوة \nوتمجيد الألم نشأت \nبالفعل، وسأعرض لك",
        ), (
            "لكن لا بد أن أوضح لك أن كل ه[/green]ذه الأفكار[green] المغلوطة حو[/red]ل استنكار  النشوة وتمجيد الألم نشأت بالفعل، وسأعرض لك التفاصيل لتكتشف حقيقة و[red]أساس تلك السعادة",
            "لكن لا بد أن أوضح لك \e[0m\nأن كل ه\e[39mذه الأفكار\e[32m \e[0m\n\e[39m\e[32mالمغلوطة ح\e[39m\e[32mول استنكار\e[0m\n\e[39m\e[32mر  النشوة وتمجيد الأل\e[0m\nلم نشأت بالفعل، وسأعر\e[0m\nرض لك التفاصيل لتكتشف\e[0m\nف ح\e[31mقيقة وأساس تلك الس\e[0m\n\e[31mسعادة\e[0m"
        ), (
            "ต้าอ่วยวาทกรรมอาว์เซี้ยว กระดี๊กระด๊า ช็อปซาดิสต์โมจิดีพาร์ตเมนต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
            "ต้าอ่วยวาทกรรมอาว์เซี้ยว \nกระดี๊กระด๊า ช็อปซาดิสต์โม\nมจิดีพาร์ตเมนต์ อินดอร์วิว สี่\n่แยกมาร์กจ๊อกกี้ โซนี่บัตเตอ\nอร์ฮันนีมูน ยาวีแพลนหงวนสค\nคริปต์ แจ็กพ็อตต่อรองโทรโข่\n่งยากูซ่ารุมบ้า บอมบ์เบอร์รี\nีวีเจดีพาร์ทเมนท์ บอยคอตต์\n์เฟอร์รี่บึมมาราธอน "
        ), (
            "ต้าอ่วยวาท[red]กรรมอาว์เซี้ยว กระดี๊กระด๊า [/red]ช็อปซาดิสต์โมจิดีพาร์ตเม[blue underline]นต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเต[/blue underline]อร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
            "ต้าอ่วยวาท\e[31mกรรมอาว์เซี้ยว \e[0m\n\e[31mกระดี๊กระด๊า \e[39mช็อปซาดิสต์โม\e[0m\n\e[39mมจิดีพาร์ตเ\e[4m\e[34mมนต์ อินดอร์วิว สี่\e[0m\n\e[4m\e[34m่แยกมาร์กจ๊อกกี้ โซนี่บัต\e[24m\e[39mเตอ\e[0m\n\e[24m\e[39mอร์ฮันนีมูน ยาวีแพลนหงวนสค\e[0m\nคริปต์ แจ็กพ็อตต่อรองโทรโข่\e[0m\n่งยากูซ่ารุมบ้า บอมบ์เบอร์รี\e[0m\nีวีเจดีพาร์ทเมนท์ บอยคอตต์\e[0m\n์เฟอร์รี่บึมมาราธอน \e[0m"
        ), (
            "국가유공자·상이군경 및 전몰군경의 유가족은 법률이 정하는 바에 의하여",
            "국가유공자·상이군경 \n및 전몰군경의 유가족\n족은 법률이 정하는 바\n바에 의하여"
        ), (
            "국[red]가유공자·상이군[bold]경 및 전[/bold]몰군경의 유[/red]가족은 법률이 정하는 바에 의하여",
            "국\e[31m가유공자·상이군\e[1m경 \e[0m\n\e[31m\e[1m및 전\e[22m\e[31m몰군경의 유\e[39m가족\e[0m\n\e[22m\e[31m\e[39m족은 법률이 정하는 바\e[0m\n바에 의하여\e[0m"
        ), (
            "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────",
            "┌────────────────┬───\n──────────────┬──────\n───────────┬─────────\n────────┬────────────\n───"
        ), (
            "┌────────────abcde────┬──────────── ────┬────────abcde fghi────────┬────────────────┬──────────────",
            "┌────────────abcde───\n──┬──────────── ────┬\n┬────────abcde fghi──\n───────┬─────────────\n────┬──────────────"
        ), (
            "┌─────────[red]───ab[/red]cde────┬──────[green]────── ────┬────────abcde fghi[/green]────────┬────────────────┬──────────────",
            "┌─────────\e[31m───abc\e[39mde───\e[0m\n\e[31m\e[39m──┬─────\e[32m─────── ────┬\e[0m\n\e[32m┬────────abcde\e[39m fghi──\e[0m\n\e[39m───────┬─────────────\e[0m\n────┬──────────────\e[0m"
        ), (
            "┌──────────[red]────[/red]──┬[blue bold]────────────────┬──[/blue bold]──────────────┬────────────────┬──────────────end",
            "┌──────────\e[31m────\e[39m──┬\e[1m\e[34m───\e[0m\n\e[31m\e[39m\e[1m\e[34m──────────────┬─\e[22m\e[39m─────\e[0m\n\e[22m\e[39m───────────┬─────────\e[0m\n────────┬────────────\e[0m\n───end\e[0m"
        ), (
            "."^100  ,
            ".....................\n.....................\n.....................\n.....................\n................"
        ), (
            ".[red]|||[/red]...."^10,
            ".\e[31m|||\e[39m.....\e[31m|||\e[39m.....\e[31m|||\e[39m.\e[0m\n\e[31m\e[39m\e[31m\e[39m\e[31m\e[39m....\e[31m|||\e[39m.....\e[31m|||\e[39m.....\e[31m|\e[0m\n\e[31m\e[39m\e[31m\e[39m\e[31m||\e[39m.....\e[31m|||\e[39m.....\e[31m|||\e[39m...\e[0m\n\e[39m\e[31m\e[39m\e[31m\e[39m..\e[31m|||\e[39m.....\e[31m|||\e[39m....\e[0m"
        ), (
            ".|||...."^10,
            ".|||.....|||.....|||.\n....|||.....|||.....|\n||.....|||.....|||...\n..|||.....|||...."
        )
    ]

    for (s1, s2) in strings
        reshaped = reshape_text(s1, 21)
        @test reshaped == s2
    end



end