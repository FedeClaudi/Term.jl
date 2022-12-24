import Term:
    unescape_brackets,
    escape_brackets,
    unspace_commas,
    remove_markup,
    replace_text,
    reshape_text,
    remove_ansi,
    split_lines,
    join_lines,
    has_markup,
    cleantext,
    textwidth,
    has_ansi,
    textlen,
    fillin,
    chars,
    justify,
    str_trunc,
    reshape_code_string

import Term.Colors: nospaces
import Term.Style: apply_style
import Term.Measures: width as get_width

@testset "TU_markup" begin
    strings = [
        (
            "this is {red} some {blue} text {/blue} that I like{/red}",
            "this is  some  text  that I like",
        ),
        (
            "{bold underline} this is {red on_green} text {/red on_green} I like {/bold underline}",
            " this is  text  I like ",
        ),
    ]

    for (s1, s2) in strings
        @test has_markup(s1)
        @test remove_markup(s1) == s2
        @test cleantext(s1) == s2
        @test textlen(s1) == textwidth(s2)
    end

    @test remove_markup("text with {{double}} squares") == "text with {{double}} squares"
    @test !has_markup("text with {{double}} squares")

    text = "{red}asdasda{/green}a{blue}sda{/blue}sda{/red}"

    @test remove_markup(text) == "asdasdaasdasda"
    @test remove_markup(text; remove_orphan_tags = false) == "asdasda{/green}asdasda"
end

@testset "TU_ansi" begin
    apply_style("test{(.2, .5, .6)}coloooor{/(.2, .5, .6)}")
    strings = [
        (
            "this is \e[31m some \e[34m text \e[39m\e[31m that I like\e[39m",
            "this is  some  text  that I like",
            "\e[39m",
        ),
        (
            "\e[1m\e[4m this is \e[31m\e[42m text \e[39m\e[49m\e[4m I like \e[22m\e[24m",
            " this is  text  I like ",
            "\e[24m",
        ),
        (
            "test\e[38;2;51;128;153mcoloooor\e[39m and white",
            "testcoloooor and white",
            "\e[39m",
        ),
    ]

    for (s1, s2, ltag) in strings
        @test has_ansi(s1)
        @test remove_ansi(s1) == s2
    end
end

@testset "TU_replace_text" begin
    text = "abcdefghilmnopqrstuvz"

    @test replace_text(text, 0, 5, "aaa") == "aaafghilmnopqrstuvz"
    @test replace_text(text, 0, 5, ',') == ",,,,,fghilmnopqrstuvz"

    @test replace_text(text, 18, 21, "aaa") == "abcdefghilmnopqrstaaa"
    @test replace_text(text, 18, 21, ',') == "abcdefghilmnopqrst,,,"

    @test replace_text(text, 10, 15, "aaa") == "abcdefghilaaarstuvz"
    @test replace_text(text, 10, 15, ',') == "abcdefghil,,,,,rstuvz"

    @test nospaces("a (1, 2, 3) 4") == "a(1,2,3)4"

    @test unspace_commas("a, 2, 3") == "a,2,3"
end

@testset "TU_misc" begin
    @test chars("abcd") == ['a', 'b', 'c', 'd']

    strings = [
        "aaa\nadasda\nasdasda",
        """
        asdasd
adsada
asddsa""",
    ]
    for str in strings
        @test join_lines(split_lines(str)) == str
    end
end

@testset "TU_reshape" begin
    strings = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "Lorem {red}ipsum dolor sit {underline}amet, consectetur{/underline} adipiscing elit, {/red}{blue}sed do eiusmod tempor incididunt{/blue} ut labore et dolore magna aliqua.",
        "Lorem{red}ipsumdolorsit{underline}amet, consectetur{/underline} adipiscing elit, {/red}seddoeiusmo{blue}dtemporincididunt{/blue}ut labore et dolore magna aliqua.",
        "ต้าอ่วยวาทกรรมอาว์เซี้ยว กระดี๊กระด๊า ช็อปซาดิสต์โมจิดีพาร์ตเมนต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
        "ต้าอ่วยวาท{red}กรรมอาว์เซี้ยว กระดี๊กระด๊า {/red}ช็อปซาดิสต์โมจิดีพาร์ตเม{blue underline}นต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเต{/blue underline}อร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
        "국가유공자·상이군경 및 전몰군경의 유가족은 법률이 정하는 바에 의하여",
        "국{red}가유공자·상이군{bold}경 및 전{/bold}몰군경의 유{/red}가족은 법률이 정하는 바에 의하여",
        "朗眠裕安無際集正聞進士健音社野件草売規作独特認権価官家複入豚末告設悟自職遠氷育教載最週場仕踪持白炎組特曲強真雅立覧自価宰身訴側善論住理案者券真犯著避銀楽験館稿告",
        "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────",
        "┌────────────abcde────┬──────────── ────┬────────abcde fghi────────┬────────────────┬──────────────",
        "┌─────────{red}───ab{/red}cde────┬──────{green}────── ────┬────────abcde fghi{/green}────────┬────────────────┬──────────────",
        "┌──────────{red}────{/red}──┬{blue bold}────────────────┬──{/blue bold}──────────────┬────────────────┬──────────────end",
        "."^100,
        ".{red}|||{/red}...."^10,
        ".|||...."^10,
    ]

    width = 33
    debug = false
    for (i, txt) in enumerate(strings)
        reshaped = reshape_text(txt, width)
        lens = length.(split(cleantext(reshaped), '\n'))

        # println(width, lens)
        # println(apply_style(reshaped))
        # println("_"^width)

        if length(txt) == ncodeunits(txt) && !occursin('\n', txt)
            (debug && any(lens .> width)) && println(lens)
            @test all(lens .≤ width)
        end
        IS_WIN || @compare_to_string reshaped "reshaped_text_$(i)"
    end

    for width in (40, 60, 99)
        rh = reshape_text(strings[1], width)
        @test all(textlen.(split(rh, '\n'); remove_orphan_tags = true) .≤ width)
    end
end

@testset "Text justify" begin
    str = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    _str = reshape_text(str, 50)

    IS_WIN || @compare_to_string(justify(str, 150), "justify")

    txt = "adsda\nadasda\nergeer\nxcvxvxvx\naasdada"
    IS_WIN || @compare_to_string(fillin(txt), "fill_in_1")
    IS_WIN || @compare_to_string(fillin(txt; bg = "red"), "fill_in_2")
end

@testset "str_trunc" begin
    str = "Lorem ipsum dolor sit amet,\n consectetur adipiscing elit, sed do eiusmod \ntempor incididunt ut labore et dolore\n magna aliqua."

    for (i, w) in enumerate((12, 51, 31))
        IS_WIN || @compare_to_string(str_trunc(str, w), "str_trunc_$(i)")
    end
end

@testset "code reshaping" begin
    codes = [
        "{#f2d777}Table{/#f2d777}(data::Matrix{Float64}; kwargs::Base.Pairs{Symbol, Union{}, Tuple{}, NamedTuple{(), Tuple{}}})",
        "{}}, Tuple{{}}, NamedTuple{(), Tuple{{}}}}){#f2d777}Table{/#f2d777}",
        "{#f2d777}Table{/#f2d777}(tb::Tables.MatrixTable{Matrix{Float64}}; box::Symbol, style::String, hpad::Int64, vpad::Int64, vertical_justify::Symbol, show_header::Bool, header::Nothing, header_style::String, header_justify::Nothing, columns_style::String, columns_justify::Symbol, columns_widths::Nothing, footer::Nothing, footer_style::String, footer_justify::Symbol, compact::Bool)",
        "{#f2d777}calc_columns_widths{/#f2d777}(N_cols::Int64, N_rows::Int64, columns_widths::Nothing, show_header::Bool, header::Tuple{String, String, String}, tb::Tables.MatrixTable{Matrix{Float64}}, sch::Tables.Schema{(:Column1, :Column2, :Column3), Tuple{Float64, Float64, Float64}}, footer::Nothing, hpad::Vector{Int64})",
        """(::Term.Tables.var"#1#3"{Tables.MatrixTable{Matrix{Float64}}})(c::Symbol)""",
    ]

    widths = (32, 65, 88)

    for (i, c) in enumerate(codes), (j, w) in enumerate(widths)
        reshaped = reshape_code_string(c, w)
        @test get_width(reshaped) <= w
        IS_WIN || @compare_to_string reshaped "reshaped_code_$(i)_$(j)"
    end
end

@testset "markup reshaping" begin
    txts = [
        "{red}dasda asda dadasda{green}aadasdad{/green}dad asd ad ad ad asdad{bold}adada ad as sad ad ada{/red}ad adas sd ads {/bold}",
        "{red}adasd ad sa dsa{green} ad {blue} sd d ads ad {/blue}da dad {/green} asdsa dad a {/red}",
        "{red}adasd ad sa dsa{bold} ad {blue} sd d ads ad {/blue}da dad {/bold} asdsa dad a {/red}",
        "{red}adasd ad sa dsa{green} ad {blue} sd d ads ad da dad {/green} asdsa ddfsf {/blue}ad a {/red}",
        "{on_red}adasd ad sa dsa{green} ad {on_black} sd d ads ad da{/on_black} dad {/green} asdsa ddfsf ad a {/on_red}",
        "{on_(25, 25, 25)}adasd ad sa dsa{green} ad {on_black} sd d ads ad da{/on_black} {white}dad{/white} asad {/green} asdsa ddfsf ad a {/on_(25, 25, 25)}",
        "{(220, 180, 150)} pink {bold}pink bold {dodger_blue2} pink bold blue {/dodger_blue2} pink bold {/bold} pink {on_(25, 55, 100)} pink on blue {/(220, 180, 150)} just on blue {/on_(25, 55, 100)} NOW SIMPLE WHITE {red} red red red {/red} white white {underline} underline underline {/underline}",
    ]
    widths = (32, 65, 20)

    for (i, txt) in enumerate(txts)
        for (j, w) in enumerate(widths)
            reshaped = reshape_text(txt, w)
            IS_WIN || @compare_to_string reshaped "reshaped_text_markuo_$(j)_$(i)"
        end
    end
end
