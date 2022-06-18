import Term: Panel, TextBox
import Term.Layout: PlaceHolder

@testset "\e[34mPanel - no content" begin
    @test size(Panel(height = 4, width = 3)) == (4, 3)

    for style in ("default", "red", "on_blue")
        testpanel(Panel(fit = true, style = style), 3, 2)
        testpanel(Panel(), 88, 2)
        testpanel(Panel(height = 4, width = 12, style = style), 12, 4)
    end
end

@testset "\e[34mPanel - fit basic shape" begin
    testpanel(Panel("MYTEXT"; height = 10, width = 60), 60, 10)
    testpanel(Panel("MYTEXT"; width = 60), 60, 3)
    testpanel(Panel("MYTEXT"), 12, 3)

    testpanel(Panel("MYTEXT"; height = 10, width = 60, padding = (4, 4, 2, 2)), 60, 10)
    testpanel(Panel("MYTEXT"; width = 60, padding = (4, 4, 2, 2)), 60, 7)
    testpanel(Panel("MYTEXT"; padding = (4, 4, 2, 2)), 16, 7)
end

@testset "\e[34mPanel - fit overflow" begin
    testpanel(
        Panel(
            Panel("MYTEXT"^50; height = 10, width = 60) /
            Panel("MYTEXT"^50; height = 10, width = 60),
        ),
        console_width() - 1,
        nothing,
    )
end

@testset "\e[34mPANEL - fit - measure" begin
    for style in ("default", "red", "on_blue")
        # ----------------------------- text only content ---------------------------- #
        _kw = (fit = true, style = style)
        testpanel(Panel("t"; _kw...), 7, 3)
        testpanel(Panel("test"; _kw...), 10, 3)
        testpanel(Panel("1234\n123456789012"; _kw...), 18, 4)
        testpanel(Panel("나랏말싸미 듕귁에 달아"; _kw...), 28, 3)
        testpanel(Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; _kw...), 28, 4)
        testpanel(Panel("."^500; _kw...), displaysize(stdout)[2] - 1, nothing)

        # ------------------------------- nested panels ------------------------------ #
        testpanel(Panel(Panel("test"; _kw...); _kw...), 16, 5)

        testpanel(
            Panel(Panel(Panel("."; _kw...); _kw...); fit = true, style = style),
            19,
            7,
        )
    end
end

# @testset "\e[34mPANEL - nofit - measure" begin
#     for style in ("default", "red", "on_blue")
#         testpanel(Panel("t"; style = style, fit = false), 88, 3)
#         testpanel(Panel("test"; style = style, fit = false), 88, 3)
#         testpanel(Panel("1234\n123456789012"; style = style, fit = false), 88, 4)
#         testpanel(Panel("나랏말싸미 듕귁에 달아"; style = style, fit = false), 88, 3)
#         testpanel(
#             Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; style = style, fit = false),
#             88,
#             4,
#         )
#         for justify in (:left, :center, :right)
#             # ----------------------------- text only content ---------------------------- #
#             _kw = (justify = justify, style = style)
#             _nofit = (; fit = false, _kw...)
#             testpanel(Panel("."^1500; _nofit...), 88, 21)

#             # ------------------------------- nested panels ------------------------------ #
#             testpanel(Panel(Panel("test"); fit = true, _kw...), 16, 5)

#             testpanel(Panel(Panel(Panel("."); _nofit...); _nofit...), 88, 7)

#             testpanel(Panel(Panel("."^250); _nofit...), 88, 5)

#             testpanel(Panel(Panel("test"; _kw...); fit = false), 88, 5)

#             testpanel(Panel(Panel(Panel("."; _kw...); _kw...); fit = false), 88, 7)

#             testpanel(Panel(Panel("."^250; _kw...); fit = false), 88, 5)

#             testpanel(Panel(Panel("t1"; _kw...), Panel("t2"; _kw...); fit = false), 88, 8)

#             _kw = (fit = false, width = 30, height = 8)
#             testpanel(Panel(Panel("test"; width = 22); _kw...), 30, 8)

#             testpanel(Panel(Panel("test"; width = 42); _kw...), 30, 8)

#             testpanel(
#                 Panel(
#                     Panel("test"; height = 12, width = 42);
#                     fit = false,
#                     height = 8,
#                     width = 30,
#                 ),
#                 30,
#                 8,
#             )
#         end
#     end
# end

@testset "\e[34mPANEL - FIT - measure" begin
    testpanel(Panel("t"; fit = true), 7, 3)
    testpanel(Panel("test"; fit = true), 10, 3)
    testpanel(Panel("1234\n123456789012"; fit = true), 18, 4)
    testpanel(Panel("나랏말싸미 듕귁에 달아"; fit = true), 28, 3)
    testpanel(Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; fit = true), 28, 4)
    for justify in (:left, :center, :right)
        # ----------------------------- text only content ---------------------------- #
        _kw = (fit = true, justify = justify)
        testpanel(Panel("."^1500; _kw...), console_width() - 1, nothing)

        # ------------------------------- nested panels ------------------------------ #
        testpanel(Panel(Panel("test"); _kw...), 16, 5)

        testpanel(Panel(Panel(Panel("."); _kw...); _kw...), 19, 7)

        testpanel(Panel(Panel("."^250); _kw...), console_width() - 1, nothing)

        testpanel(Panel(Panel("test"; justify = justify); fit = true), 16, 5)

        testpanel(
            Panel(Panel(Panel("."; justify = justify); justify = justify); fit = true),
            19,
            7,
        )

        testpanel(
            Panel(Panel("."^250; justify = justify); fit = true),
            console_width() - 1,
            nothing,
        )

        testpanel(
            Panel(
                Panel("t1"; justify = justify),
                Panel("t2"; justify = justify);
                fit = true,
            ),
            14,
            8,
        )

        _kw = (fit = true, width = 30, height = 8)
        testpanel(Panel(Panel("test"; width = 22); _kw...), 30, 8)

        testpanel(Panel(Panel("test"; width = 42); _kw...), 48, 8)

        testpanel(Panel(Panel("test"; height = 12, width = 42); _kw...), 48, 14)
    end
end

@testset "PANEL - centered title style" begin
    @test string(
        Panel(title = "test", width=88, title_justify = :left, title_style = "italic red"),
    ) ==
          "\e[22m╭──── \e[3m\e[31mtest\e[23m\e[39m\e[22m\e[22m ────────────────────────────────────────────────────────────────────────────╮\e[22m\e[0m\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"
    @test string(
        Panel(title = "test", width=88, title_justify = :center, title_style = "italic red"),
    ) ==
          "\e[22m╭────────────────────────────────────────\e[22m \e[3m\e[31mtest\e[23m\e[39m\e[22m\e[22m ────────────────────────────────────────╮\e[22m\e[0m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"
    @test string(
        Panel(title = "test", width=88, title_justify = :right, title_style = "italic red"),
    ) ==
          "\e[22m╭───────────────────────────────────────────────────────────────────────────── \e[3m\e[31mtest\e[23m\e[39m\e[22m\e[22m ───╮\e[22m\e[0m\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"

    @test string(Panel(title = "test", width=88, title_justify = :left)) ==
          "\e[22m╭──── test\e[22m ────────────────────────────────────────────────────────────────────────────╮\e[22m\e[0m\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"
    @test string(Panel(title = "test", width=88, title_justify = :center)) ==
          "\e[22m╭────────────────────────────────────────\e[22m test\e[22m ────────────────────────────────────────╮\e[22m\e[0m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"
    @test string(Panel(title = "test", width=88, title_justify = :right)) ==
          "\e[22m╭───────────────────────────────────────────────────────────────────────────── test\e[22m ───╮\e[22m\e[0m\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"

    p = Panel(
        title = "test",
        title_justify = :left,
        subtitle = "aaaaa",
        subtitle_justify = :right,
        width = 22,
    )
    @test string(p) ==
          "\e[22m╭──── test\e[22m ──────────╮\e[22m\e[0m\e[22m\n\e[22m╰────────── aaaaa\e[22m ───╯\e[22m\e[0m\e[22m\e[0m"
end

@testset "PANEL - compare to string" begin
    pts = """
Lorem{red} ipsum dolor s{/red}it amet, consectetur adipiscing elit,
ed do eiusmod tempor {bold blue}incididu{underline}nt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nos{/underline}trud exercitation ullamco laboris nisi ut aliquip ex 
ea commodo consequat. Duis aute {/bold blue}{red on_black}irure dolor in reprehenderit 
in voluptate velit esse cillum dolore eu fugiat nulla 
pariatur. Excepteur sint occaecat{/red on_black} cupidatat non proident, 
sunt in {green}culpa qui officia{/green} deserunt mollit anim 
id est laborum."""

    pts = replace(pts, "\n" => "")

    pts2 = replace(
        """
Lorem ipsum {bold}dolor sit{/bold} amet, consectetur adipiscing elit,
ed do e{red}iusmod tempor incididunt{/red} ut {bold}labore et {underline}dolore{/underline} magna aliqua.{/bold} Ut enim ad minim
veniam, quis{green} nostrud exercitation {on_black}ullamco laboris nisi ut aliquip ex {/on_black}
ea commodo consequat.{blue} Duis aute irure dolor in{/blue} reprehenderit 
in voluptate velit{/green} esse {italic}cillum dolore{/italic}{red} eu{/red}{italic green} fugiat {/italic green}nulla 
pariatur. Excepteur{red} sint{/red}{blue} occaecat cupidatat {/blue}non proident, 
sunt in culpa qui {italic}officia{/italic} deserunt mollit anim 
id est laborum.""",
        "\n" => "",
    )

    @test string(Panel(pts2; fit = false, width = 44)) ==
          "\e[22m╭──────────────────────────────────────────╮\e[22m\n\e[0m\e[22m│\e[22m\e[0m  Lorem ipsum \e[1mdolor sit\e[22m amet,             \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  consectetur adipiscing elit,ed do       \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  e\e[31miusmod tempor incididunt\e[39m\e[22m ut \e[1mlabore     \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  et \e[4mdolore\e[24m\e[1m magna aliqua.\e[22m Ut enim ad      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  minimveniam, quis\e[32m nostrud               \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  exercitation \e[40mullamco laboris nisi ut    \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  aliquip ex \e[49m\e[32mea commodo consequat.\e[34m Duis   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  aute irure dolor in\e[39m\e[32m reprehenderit in    \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  voluptate velit\e[39m\e[22m esse \e[3mcillum dolore\e[23m\e[22m\e[31m eu\e[39m\e[22m\e[3m\e[32m   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  fugiat \e[23m\e[22m\e[39m\e[3mnulla pariatur. Excepteur\e[31m sint\e[39m\e[3m\e[34m   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  occaecat cupidatat \e[39m\e[3mnon proident, sunt   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  in culpa qui \e[3mofficia\e[23m\e[3m deserunt mollit    \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  anim id est laborum.                    \e[0m\e[22m│\e[22m\e[0m\n\e[22m╰──────────────────────────────────────────╯\e[22m\e[0m"

    @test string(Panel(pts2; fit = false, width = 51)) ==
          "\e[22m╭─────────────────────────────────────────────────╮\e[22m\n\e[0m\e[22m│\e[22m\e[0m  Lorem ipsum \e[1mdolor sit\e[22m amet, consectetur        \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  adipiscing elit,ed do e\e[31miusmod tempor           \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  incididunt\e[39m\e[22m ut \e[1mlabore et \e[4mdolore\e[24m\e[1m magna aliqua.\e[22m   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  Ut enim ad minimveniam, quis\e[32m nostrud           \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  exercitation \e[40mullamco laboris nisi ut aliquip   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  ex \e[49m\e[32mea commodo consequat.\e[34m Duis aute irure       \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  dolor in\e[39m\e[32m reprehenderit in voluptate velit\e[39m\e[22m      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  esse \e[3mcillum dolore\e[23m\e[22m\e[31m eu\e[39m\e[22m\e[3m\e[32m fugiat \e[23m\e[22m\e[39m\e[3mnulla pariatur.   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  Excepteur\e[31m sint\e[39m\e[3m\e[34m occaecat cupidatat \e[39m\e[3mnon          \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  proident, sunt in culpa qui \e[3mofficia\e[23m\e[3m deserunt   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  mollit anim id est laborum.                    \e[0m\e[22m│\e[22m\e[0m\n\e[22m╰─────────────────────────────────────────────────╯\e[22m\e[0m"

    @test string(Panel(pts2; fit = false, width = 67)) ==
          "\e[22m╭─────────────────────────────────────────────────────────────────╮\e[22m\n\e[0m\e[22m│\e[22m\e[0m  Lorem ipsum \e[1mdolor sit\e[22m amet, consectetur adipiscing elit,ed     \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  do e\e[31miusmod tempor incididunt\e[39m\e[22m ut \e[1mlabore et \e[4mdolore\e[24m\e[1m magna         \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  aliqua.\e[22m Ut enim ad minimveniam, quis\e[32m nostrud exercitation      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  \e[40mullamco laboris nisi ut aliquip ex \e[49m\e[32mea commodo consequat.\e[34m       \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  Duis aute irure dolor in\e[39m\e[32m reprehenderit in voluptate velit\e[39m\e[22m      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  esse \e[3mcillum dolore\e[23m\e[22m\e[31m eu\e[39m\e[22m\e[3m\e[32m fugiat \e[23m\e[22m\e[39m\e[3mnulla pariatur. Excepteur\e[31m sint\e[39m\e[3m\e[34m    \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  occaecat cupidatat \e[39m\e[3mnon proident, sunt in culpa qui \e[3mofficia\e[23m\e[3m     \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  deserunt mollit anim id est laborum.                           \e[0m\e[22m│\e[22m\e[0m\n\e[22m╰─────────────────────────────────────────────────────────────────╯\e[22m\e[0m"

    circle = """
          oooo    
       oooooooooo 
      oooooooooooo
      oooooooooooo
       oooooooooo 
          oooo    """
    p = Panel(circle; fit = true, padding = (0, 0, 0, 0))
    @test string(p) ==
          "\e[22m╭────────────╮\e[22m\n\e[0m\e[22m│\e[22m\e[0m    oooo    \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m oooooooooo \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0moooooooooooo\e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0moooooooooooo\e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m oooooooooo \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m    oooo    \e[0m\e[22m│\e[22m\e[0m\n\e[22m╰────────────╯\e[22m\e[0m"

    p = Panel(
        "test"^25;
        height = 22,
        width = 49,
        box = :HEAVY,
        justify = :center,
        title = "description",
        title_justify = :center,
        title_style = "bold bright_blue",
        padding = (2, 4, 4, 2),
        fit = false,
    )
    @test size(p.measure) == (22, 49)

    p = Panel(
        "test"^25;
        height = 22,
        width = 49,
        box = :SIMPLE,
        justify = :center,
        title = "description",
        title_justify = :center,
        title_style = "bold bright_blue",
        padding = (2, 4, 4, 2),
        fit = false,
    )
    @test size(p.measure) == (22, 49)

    p = Panel(
        PlaceHolder(60, 30);
        height = 22,
        width = 49,
        box = :HEAVY,
        justify = :center,
        title = "description",
        title_justify = :center,
        title_style = "bold bright_blue",
        padding = (2, 0, 2, 0),
        fit = false,
    )
    @test size(p.measure) == (22, 49)
end

@testset "\e[34mPanel + renderables" begin
    testpanel(Panel(RenderableText("x" .^ 5)), 11, 3)

    testpanel(Panel(RenderableText("x" .^ 500); fit = false), 88, 9)

    testpanel(Panel(RenderableText("x" .^ 5); fit = true), 11, 3)

    testpanel(
        Panel(RenderableText("x" .^ 500); fit = true),
        displaysize(stdout)[2] - 1,
        nothing,
    )
end

@testset "\e[34mPANEL - titles" begin
    style = "red"
    for fit in (true, false)
        for justify in (:left, :center, :right)
            testpanel(
                Panel(
                    "."^50;
                    title = "test",
                    title_style = style,
                    title_justify = justify,
                    subtitle = "subtest",
                    subtitle_style = style,
                    subtitle_justify = justify,
                    fit = fit,
                ),
                fit ? nothing : 88,
                3,
            )
        end
    end
end

@testset "\e[34mPanel - padding" begin
    p = Panel("."^24; padding = (4, 4, 2, 2), fit = false)
    testpanel(p, 88, 7)

    p = Panel("."^24; padding = (4, 4, 2, 2), fit = true)
    testpanel(p, 34, 7)
end

@testset "\e[34mPanel - background" begin
    p = Panel(apply_style(
        """
    asasd
asdasadas
asdsasdasdsadasdsa
ads
    """,
        "on_blue",
    ); background = "on_red")
    @test string(p) ==
          "\e[22m╭──────────────────────╮\e[22m\n\e[0m\e[22m│\e[22m\e[0m\e[41m  \e[49m\e[0m\e[44m    asasd\e[49m\e[41m         \e[49m\e[41m  \e[49m\e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m\e[41m  \e[49m\e[0m\e[44masdasadas\e[49m\e[41m         \e[49m\e[41m  \e[49m\e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m\e[41m  \e[49m\e[0m\e[44masdsasdasdsadasdsa\e[49m\e[41m\e[49m\e[41m  \e[49m\e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m\e[41m  \e[49m\e[0m\e[44mads\e[49m\e[41m               \e[49m\e[41m  \e[49m\e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m\e[41m  \e[49m\e[0m\e[44m    \e[49m\e[41m              \e[49m\e[41m  \e[49m\e[0m\e[22m│\e[22m\e[0m\n\e[22m╰──────────────────────╯\e[22m\e[0m"
end
