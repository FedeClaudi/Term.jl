import Term:
    get_last_ANSI_code,
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
        @test get_last_ANSI_code(s1) == ltag
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
    str = """
Lorem ipsum {bold}dolor sit{/bold} amet, consectetur adipiscing elit,
ed do e{red}iusmod tempor incididunt{/red} ut {bold}labore et {underline}dolore{/underline} magna aliqua.{/bold} Ut enim ad minim
veniam, quis{green} nostrud exercitation {on_black}ullamco laboris nisi ut aliquip ex {/on_black}
ea commodo consequat.{blue} Duis aute irure dolor in{/blue} reprehenderit 
in voluptate velit{/green} esse {italic}cillum dolore{/italic}{red} eu{/red}{italic green} fugiat {/italic green}nulla 
pariatur. Excepteur{red} sint{/red}{blue} occaecat cupidatat {/blue}non proident, 
sunt in culpa qui {italic}officia{/italic} deserunt mollit anim 
id est laborum."""

    str_reshaped = "Lorem ipsum {bold}dolor sit{/bold} amet,\nconsectetur adipiscing elit,\ned do e{red}iusmod tempor incididunt{/red}\nut {bold}labore et {underline}dolore{/underline} magna aliqua.{/bold}\n{bold}{/bold} Ut enim ad minim\nveniam, quis{green} nostrud exercitation{/green}\n{green} {on_black}ullamco laboris nisi ut aliquip{/green}\n{green}{on_black}ex {/on_black}{/green}\nea commodo consequat.{blue} Duis aute{/blue}\n{blue}irure dolor in{/blue} reprehenderit\nin voluptate velit{/green} esse {italic}cillum{/italic}\n{italic}dolore{/italic}{red} eu{/red}{italic green} fugiat {/italic green}nulla\npariatur. Excepteur{red} sint{/red}{blue} occaecat{/blue}\n{blue} cupidatat {/blue}non proident,\nsunt in culpa qui {italic}officia{/italic} deserun\nt mollit anim\nid est laborum."

    logo_str = """Term.jl is a {#9558B2}Julia{/#9558B2} package for creating styled terminal outputs.

    Term provides a simple {italic green4 bold}markup language{/italic green4 bold} to add {bold bright_blue}color{/bold bright_blue} and {bold underline}styles{/bold underline} to your text.
    More complicated text layout can be created using {red}"Renderable"{/red} objects such 
    as {red}"Panel"{/red} and {red}"TextBox"{/red}.
    These can also be nested and stacked to create {italic pink3}fancy{/italic pink3} and {underline}informative{/underline} terminal ouputs for your Julia code"""

    logo_str_reshaped = "Term.jl is a {#9558B2}Julia{/#9558B2} package for\ncreating styled terminal outputs.\n\nTerm provides a simple {italic green4 bold}markup{/italic green4 bold}\n{italic green4 bold}language{/italic green4 bold} to add {bold bright_blue}color{/bold bright_blue} and {bold underline}styles{/bold underline}\nto your text.\nMore complicated text layout\ncan be created using {red}\"Renderable\"{/red}\n{red}{/red} objects such\nas {red}\"Panel\"{/red} and {red}\"TextBox\"{/red}.\nThese can also be nested and\nstacked to create {italic pink3}fancy{/italic pink3} and\n{underline}informative{/underline} terminal ouputs\nfor your Julia code"

    strings = [
        (
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            "Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit,\nsed do eiusmod tempor incididunt\nut labore et dolore magna aliqua.",
        ),
        (
            "Lorem {red}ipsum dolor sit {underline}amet, consectetur{/underline} adipiscing elit, {/red}{blue}sed do eiusmod tempor incididunt{/blue} ut labore et dolore magna aliqua.",
            "Lorem {red}ipsum dolor sit {underline}amet,{/red}\n{red}{underline}consectetur{/underline} adipiscing elit,{/red}\n{red}{/red}{blue}sed do eiusmod tempor incididunt{/blue}\nut labore et dolore magna aliqua.",
        ),
        (
            "Lorem{red}ipsumdolorsit{underline}amet, consectetur{/underline} adipiscing elit, {/red}seddoeiusmo{blue}dtemporincididunt{/blue}ut labore et dolore magna aliqua.",
            "Lorem{red}ipsumdolorsit{underline}amet, consectet{/red}\n{red}{underline}ur{/underline} adipiscing elit, {/red}seddoeiusmo{blue}dt{/blue}\n{blue}emporincididunt{/blue}ut labore et\ndolore magna aliqua.",
        ),
        (
            "ต้าอ่วยวาทกรรมอาว์เซี้ยว กระดี๊กระด๊า ช็อปซาดิสต์โมจิดีพาร์ตเมนต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
            "ต้าอ่วยวาทกรรมอาว์เซี้ยว กระดี๊กระด๊า\nช็อปซาดิสต์โมจิดีพาร์ตเมนต์ อินดอร์วิว\nสี่แยกมาร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน\nยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข\n่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์\nบอยคอตต์เฟอร์รี่บึมมาราธอน",
        ),
        (
            "ต้าอ่วยวาท{red}กรรมอาว์เซี้ยว กระดี๊กระด๊า {/red}ช็อปซาดิสต์โมจิดีพาร์ตเม{blue underline}นต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเต{/blue underline}อร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
            "ต้าอ่วยวาท{red}กรรมอาว์เซี้ยว กระดี๊กระด๊า{/red}\n{red}{/red}ช็อปซาดิสต์โมจิดีพาร์ตเม{blue underline}นต์ อินดอร์วิว{/blue underline}\n{blue underline}สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเต{/blue underline}อร์ฮันนีมูน\nยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข\n่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์\nบอยคอตต์เฟอร์รี่บึมมาราธอน",
        ),
        (
            "국가유공자·상이군경 및 전몰군경의 유가족은 법률이 정하는 바에 의하여",
            "국가유공자·상이군경 및 전몰군경의\n 유가족은 법률이 정하는 바에\n의하여",
        ),
        (
            "국{red}가유공자·상이군{bold}경 및 전{/bold}몰군경의 유{/red}가족은 법률이 정하는 바에 의하여",
            "국{red}가유공자·상이군{bold}경 및 전{/bold}몰군경의{/red}\n{red} 유{/red}가족은 법률이 정하는 바에\n의하여",
        ),
        (
            "朗眠裕安無際集正聞進士健音社野件草売規作独特認権価官家複入豚末告設悟自職遠氷育教載最週場仕踪持白炎組特曲強真雅立覧自価宰身訴側善論住理案者券真犯著避銀楽験館稿告",
            "朗眠裕安無際集正聞進士健音社野件草\n売規作独特認権価官家複入豚末告設悟\n自職遠氷育教載最週場仕踪持白炎組特\n曲強真雅立覧自価宰身訴側善論住理案\n者券真犯著避銀楽験館稿告",
        ),
        (
            "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────",
            "┌────────────────┬───────────────\n─┬────────────────┬──────────────\n──┬──────────────",
        ),
        (
            "┌────────────abcde────┬──────────── ────┬────────abcde fghi────────┬────────────────┬──────────────",
            "┌────────────abcde────┬──────────\n── ────┬────────abcde fghi───────\n─┬────────────────┬──────────────",
        ),
        (
            "┌─────────{red}───ab{/red}cde────┬──────{green}────── ────┬────────abcde fghi{/green}────────┬────────────────┬──────────────",
            "┌─────────{red}───ab{/red}cde────┬──────{green}────{/green}\n{green}── ────┬────────abcde fghi{/green}───────\n─┬────────────────┬──────────────",
        ),
        (
            "┌──────────{red}────{/red}──┬{blue bold}────────────────┬──{/blue bold}──────────────┬────────────────┬──────────────end",
            "┌──────────{red}────{/red}──┬{blue bold}───────────────{/blue bold}\n{blue bold}─┬──{/blue bold}──────────────┬──────────────\n──┬──────────────end",
        ),
        (
            "."^100,
            ".................................\n.................................\n.................................\n.",
        ),
        (
            ".{red}|||{/red}...."^10,
            ".{red}|||{/red}.....{red}|||{/red}.....{red}|||{/red}.....{red}|||{/red}.....\n{red}|||{/red}.....{red}|||{/red}.....{red}|||{/red}.....{red}|||{/red}.....{red}|\n||{/red}.....{red}|||{/red}....",
        ),
        (
            ".|||...."^10,
            ".|||.....|||.....|||.....|||.....\n|||.....|||.....|||.....|||.....|\n||.....|||....",
        ),
        (str, str_reshaped),
        (logo_str, logo_str_reshaped),
    ]

    width = 33
    debug = false
    for (i, (input, expected)) in enumerate(strings)
        reshaped = reshape_text(input, width)
        reshaped_no_ansi = remove_markup(reshaped)
        lens = length.(split(reshaped_no_ansi, '\n'))
        if debug && reshaped != expected
            println("== reshaped == ")
            println(reshaped)
            println(repr(reshaped))
            println("\n== reshaped no ansi == ")
            println(reshaped_no_ansi)
            println("\n== expected == ")
            println(expected)
        end
        # FIXME: should work when `length(input) != ncodeunits(input)` using non unit byte characters: see docs.julialang.org/en/v1/manual/strings/#Unicode-and-UTF-8
        if length(input) == ncodeunits(input) && !occursin('\n', input)
            (debug && any(lens .> width)) && println(lens)
            @test all(lens .≤ width)
        end
        @test reshaped == expected
    end

    for width in (40, 60, 99)
        rh = reshape_text(str, width)
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
    txt = "{red}dasda asda dadasda{green}aadasdad{/green}dad asd ad ad ad asdad{bold}adada ad as sad ad ada{/red}ad adas sd ads {/bold}"
    widths = (32, 65, 20)

    for (j, w) in enumerate(widths)
        reshaped = reshape_text(txt, w)
        IS_WIN || @compare_to_string reshaped "reshaped_text_markuo_$(j)"
    end
end
