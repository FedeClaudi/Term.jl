import Term: Panel, TextBox
import Term.Layout: PlaceHolder

@testset "\e[34mPanel - no content" begin
    for style in ("default", "red", "on_blue")
        testpanel(Panel(; fit = true, style = style), 3, 2)

        testpanel(Panel(), 88, 2)

        testpanel(Panel(; width = 12, height = 4, style = style), 12, 4)
    end
end

@testset "\e[34mPanel - fit basic shape" begin
    testpanel(Panel("MYTEXT"; width = 60, height = 10), 60, 10)
    testpanel(Panel("MYTEXT"; width = 60), 60, 3)
    testpanel(Panel("MYTEXT"), 12, 3)

    testpanel(Panel("MYTEXT"; width = 60, height = 10, padding = (4, 4, 2, 2)), 60, 10)
    testpanel(Panel("MYTEXT"; width = 60, padding = (4, 4, 2, 2)), 60, 7)
    testpanel(Panel("MYTEXT"; padding = (4, 4, 2, 2)), 16, 7)
end

@testset "\e[34mPanel - fit overflow" begin
    testpanel(
        Panel(
            Panel("MYTEXT"^50; width = 60, height = 10) /
            Panel("MYTEXT"^50; width = 60, height = 10),
        ),
        console_width(),
        nothing,
    )
end

@testset "\e[34mPANEL - fit - measure" begin
    for style in ("default", "red", "on_blue")
        for justify in (:left, :center, :right)
            # ----------------------------- text only content ---------------------------- #
            testpanel(Panel("t"; fit = true, style = style), 7, 3)
            testpanel(Panel("test"; fit = true, style = style), 10, 3)
            testpanel(Panel("1234\n123456789012"; fit = true, style = style), 18, 4)
            testpanel(Panel("나랏말싸미 듕귁에 달아"; fit = true, style = style), 28, 3)
            testpanel(
                Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; fit = true, style = style),
                28,
                4,
            )
            testpanel(
                Panel("."^500; fit = true, style = style),
                displaysize(stdout)[2],
                nothing,
            )

            # ------------------------------- nested panels ------------------------------ #
            testpanel(
                Panel(Panel("test"; fit = true, style = style); fit = true, style = style),
                16,
                5,
            )

            testpanel(
                Panel(
                    Panel(Panel("."; fit = true, style = style); fit = true, style = style);
                    fit = true,
                    style = style,
                ),
                19,
                7,
            )

            # @test_nothrow Panel(
            #         Panel("."^250; fit=true, style=style); fit=true, style=style
            #     )
        end
    end
end

@testset "\e[34mPANEL - nofit - measure" begin
    for style in ("default", "red", "on_blue")
        for justify in (:left, :center, :right)
            # ----------------------------- text only content ---------------------------- #
            testpanel(Panel("t"; style = style, fit = false), 88, 3)
            testpanel(Panel("test"; style = style, fit = false), 88, 3)
            testpanel(Panel("1234\n123456789012"; style = style, fit = false), 88, 4)
            testpanel(Panel("나랏말싸미 듕귁에 달아"; style = style, fit = false), 88, 3)
            testpanel(
                Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; style = style, fit = false),
                88,
                4,
            )
            testpanel(
                Panel("."^1500; justify = justify, style = style, fit = false),
                88,
                21,
            )

            # ------------------------------- nested panels ------------------------------ #
            testpanel(
                Panel(Panel("test"); fit = true, justify = justify, style = style),
                16,
                5,
            )

            testpanel(
                Panel(
                    Panel(Panel("."); fit = false, justify = justify, style = style);
                    fit = false,
                    justify = justify,
                    style = style,
                ),
                88,
                7,
            )

            testpanel(
                Panel(Panel("."^250); fit = false, justify = justify, style = style),
                88,
                6,
            )

            testpanel(
                Panel(Panel("test"; justify = justify, style = style); fit = false),
                88,
                5,
            )

            testpanel(
                Panel(
                    Panel(
                        Panel("."; justify = justify, style = style);
                        justify = justify,
                        style = style,
                    );
                    fit = false,
                ),
                88,
                7,
            )

            testpanel(
                Panel(Panel("."^250; justify = justify, style = style); fit = false),
                88,
                6,
            )

            testpanel(
                Panel(
                    Panel("t1"; justify = justify, style = style),
                    Panel("t2"; justify = justify, style = style);
                    fit = false,
                ),
                88,
                8,
            )

            testpanel(
                Panel(Panel("test"; width = 22); fit = false, width = 30, height = 8),
                30,
                8,
            )

            testpanel(
                Panel(Panel("test"; width = 42); fit = false, width = 30, height = 8),
                30,
                8,
            )

            testpanel(
                Panel(
                    Panel("test"; width = 42, height = 12);
                    fit = false,
                    width = 30,
                    height = 8,
                ),
                30,
                8,
            )
        end
    end
end

@testset "\e[34mPANEL - FIT - measure" begin
    for justify in (:left, :center, :right)
        # ----------------------------- text only content ---------------------------- #
        testpanel(Panel("t"; fit = true), 7, 3)
        testpanel(Panel("test"; fit = true), 10, 3)
        testpanel(Panel("1234\n123456789012"; fit = true), 18, 4)
        testpanel(Panel("나랏말싸미 듕귁에 달아"; fit = true), 28, 3)
        testpanel(Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; fit = true), 28, 4)
        testpanel(Panel("."^1500; justify = justify, fit = true), console_width(), nothing)

        # ------------------------------- nested panels ------------------------------ #
        testpanel(Panel(Panel("test"); fit = true, justify = justify), 16, 5)

        testpanel(
            Panel(
                Panel(Panel("."); fit = true, justify = justify);
                fit = true,
                justify = justify,
            ),
            19,
            7,
        )

        testpanel(
            Panel(Panel("."^250); fit = true, justify = justify),
            console_width(),
            nothing,
        )

        testpanel(Panel(Panel("test"; justify = justify); fit = true), 16, 5)

        testpanel(
            Panel(Panel(Panel("."; justify = justify); justify = justify); fit = true),
            19,
            7,
        )

        testpanel(
            Panel(Panel("."^250; justify = justify); fit = true),
            console_width(),
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

        testpanel(
            Panel(Panel("test"; width = 22); fit = true, width = 30, height = 8),
            30,
            8,
        )

        testpanel(
            Panel(Panel("test"; width = 42); fit = true, width = 30, height = 8),
            48,
            8,
        )

        testpanel(
            Panel(
                Panel("test"; width = 42, height = 12);
                fit = true,
                width = 30,
                height = 8,
            ),
            48,
            14,
        )
    end
end

@testset "PANEL - centered title style" begin
    @test string(
        Panel(; title = "test", title_justify = :left, title_style = "italic red"),
    ) ==
          "\e[22m╭──── \e[3m\e[31mtest\e[23m\e[39m\e[22m\e[22m ────────────────────────────────────────────────────────────────────────────╮\e[22m\e[0m\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"
    @test string(
        Panel(; title = "test", title_justify = :center, title_style = "italic red"),
    ) ==
          "\e[22m╭────────────────────────────────────────\e[22m \e[3m\e[31mtest\e[23m\e[39m\e[22m\e[22m ────────────────────────────────────────╮\e[22m\e[0m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"
    @test string(
        Panel(; title = "test", title_justify = :right, title_style = "italic red"),
    ) ==
          "\e[22m╭───────────────────────────────────────────────────────────────────────────── \e[3m\e[31mtest\e[23m\e[39m\e[22m\e[22m ───╮\e[22m\e[0m\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"

    @test string(Panel(; title = "test", title_justify = :left)) ==
          "\e[22m╭──── test\e[22m ────────────────────────────────────────────────────────────────────────────╮\e[22m\e[0m\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"
    @test string(Panel(; title = "test", title_justify = :center)) ==
          "\e[22m╭────────────────────────────────────────\e[22m test\e[22m ────────────────────────────────────────╮\e[22m\e[0m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"
    @test string(Panel(; title = "test", title_justify = :right)) ==
          "\e[22m╭───────────────────────────────────────────────────────────────────────────── test\e[22m ───╮\e[22m\e[0m\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m"

    p = Panel(;
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

    # if dotest
    #     # @test string(Panel(pts; style = "red", fit = false, width = 44)) ==
    #     # "\e[31m╭──────────────────────────────────────────╮\e[39m\n\e[0m\e[31m│\e[39m\e[0m  Lorem\e[31m ipsum dolor s\e[39mit amet,             \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  consectetur adipiscing elit,            \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  ed do                                   \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  eiusmod tempor \e[1m\e[34mincididu\e[4mnt ut labore     \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  et dolore magna aliqua. Ut enim ad      \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  minim                                   \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  veniam, quis nos\e[24m\e[34mtrud                    \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  exercitation ullamco laboris nisi ut    \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  aliquip ex                              \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│" ⋯ 266 bytes ⋯ "m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  in voluptate velit                      \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  esse cillum dolore eu fugiat nulla      \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m                                          \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  pariatur. Excepteur sint occaecat\e[39m\e[1m\e[49m\e[31m       \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  cupidatat non proident,                 \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  sunt in                                 \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  \e[32mculpa qui officia\e[39m\e[31m deserunt mollit       \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  anim                                    \e[0m\e[31m│\e[39m\e[0m\n\e[0m\e[31m│\e[39m\e[0m  id est laborum.                         \e[0m\e[31m│\e[39m\e[0m\n\e[31m╰──────────────────────────────────────────╯\e[39m\e[0m"

    #     @test string(Panel(pts; fit = false, width = 60)) ==
    #         "\e[22m╭──────────────────────────────────────────────────────────╮\e[22m\n\e[0m\e[22m│\e[22m\e[0m  Lorem\e[31m ipsum dolor s\e[39mit amet, consectetur adipiscing      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  elit,                                                   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  ed do eiusmod tempor \e[1m\e[34mincididu\e[4mnt ut labore et            \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  dolore magna aliqua. Ut enim ad minim                   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  veniam, quis                                            \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  nos\e[24m\e[34mtrud exercitation ullamco laboris nisi ut aliquip    \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  ex                                                      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  ea commodo consequat. D" ⋯ 143 bytes ⋯ "                    \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  in voluptate velit esse cillum dolore                   \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  eu fugiat nulla                                         \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  pariatur. Excepteur sint occaecat\e[39m\e[1m\e[49m\e[31m                       \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  cupidatat non proident,                                 \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  sunt in \e[32mculpa qui officia\e[39m\e[31m                               \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  deserunt mollit anim                                    \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  id est laborum.                                         \e[0m\e[22m│\e[22m\e[0m\n\e[22m╰──────────────────────────────────────────────────────────╯\e[22m\e[0m"
    # end

    @test string(Panel(pts2; fit = false, width = 44)) ==
    "\e[22m╭──────────────────────────────────────────╮\e[22m\n\e[0m\e[22m│\e[22m\e[0m  Lorem ipsum \e[1mdolor sit\e[22m amet,             \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  consectetur adipiscing elit,ed do       \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  e\e[31miusmod tempor incididunt\e[39m\e[22m ut \e[1mlabore     \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  et \e[4mdolore\e[24m\e[1m magna aliqua.\e[22m Ut enim ad      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  minimveniam, quis\e[32m nostrud               \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  exercitation \e[40mullamco laboris nisi ut    \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  aliquip ex \e[49m\e[32mea commodo consequat.\e[34m        \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  Duis aute irure dolor in\e[39m\e[32m                \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  reprehenderit in voluptate velit\e[39m\e[22m        \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  esse \e[3mcillum dolore\e[23m\e[22m\e[31m eu\e[39m\e[22m\e[3m\e[32m fugiat \e[23m\e[22m\e[39m\e[3mnulla      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  pariatur. Excepteur\e[31m sint\e[39m\e[3m\e[34m occaecat       \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  cupidatat \e[39m\e[3mnon proident, sunt in         \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  culpa qui \e[3mofficia\e[23m\e[3m deserunt mollit       \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  anim id est laborum.                    \e[0m\e[22m│\e[22m\e[0m\n\e[22m╰──────────────────────────────────────────╯\e[22m\e[0m"

    @test string(Panel(pts2; fit = false, width = 51)) ==
    "\e[22m╭─────────────────────────────────────────────────╮\e[22m\n\e[0m\e[22m│\e[22m\e[0m  Lorem ipsum \e[1mdolor sit\e[22m amet, consectetur        \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  adipiscing elit,ed do e\e[31miusmod tempor           \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  incididunt\e[39m\e[22m ut \e[1mlabore et \e[4mdolore\e[24m\e[1m magna           \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  aliqua.\e[22m Ut enim ad minimveniam, quis\e[32m           \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  nostrud exercitation \e[40mullamco laboris nisi      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  ut aliquip ex \e[49m\e[32mea commodo consequat.\e[34m Duis       \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  aute irure dolor in\e[39m\e[32m reprehenderit in           \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  voluptate velit\e[39m\e[22m esse \e[3mcillum dolore\e[23m\e[22m\e[31m eu\e[39m\e[22m\e[3m\e[32m          \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  fugiat \e[23m\e[22m\e[39m\e[3mnulla pariatur. Excepteur\e[31m sint\e[39m\e[3m\e[34m          \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  occaecat cupidatat \e[39m\e[3mnon proident, sunt in       \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  culpa qui \e[3mofficia\e[23m\e[3m deserunt mollit anim id      \e[0m\e[22m│\e[22m\e[0m\n\e[0m\e[22m│\e[22m\e[0m  est laborum.                                   \e[0m\e[22m│\e[22m\e[0m\n\e[22m╰─────────────────────────────────────────────────╯\e[22m\e[0m"

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
        width = 49,
        height = 22,
        box = :HEAVY,
        justify = :center,
        title = "description",
        title_justify = :center,
        title_style = "bold bright_blue",
        padding = (2, 4, 4, 2),
        fit = false,
    )
    @test p.measure.w == 49
    @test p.measure.h == 22

    # @test string(p) == "\e[22m┏━━━━━━━━━━━━━━━━━\e[22m \e[1m\e[38;5;12mdescription\e[22m\e[39m\e[22m ━━━━━━━━━━━━━━━━━┓\e[22m\e[39m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[" ⋯ 623 bytes ⋯ "╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ \e[22m\e[1m           \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m             \e[2m... content omitted ...\e[22m           \e[0m\e[22m┃\e[22m\e[0m\n\e[22m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\e[22m\e[0m"

    p = Panel(
        "test"^25;
        width = 49,
        height = 22,
        box = :SIMPLE,
        justify = :center,
        title = "description",
        title_justify = :center,
        title_style = "bold bright_blue",
        padding = (2, 4, 4, 2),
        fit = false,
    )
    @test p.measure.w == 49
    @test p.measure.h == 22
    # @test string(p) == "\e[22m┏━━━━━━━━━━━━━━━━━\e[22m \e[1m\e[38;5;12mdescription\e[22m\e[39m\e[22m ━━━━━━━━━━━━━━━━━┓\e[22m\e[39m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[22m╭───────────────────────────────────       \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[0m\e[22m│\e[22m\e[0m                                          \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[0m\e[22m│\e[22m\e[0m                                          \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[0m\e[22m│\e[22m\e[0m                                       " ⋯ 446 bytes ⋯ "m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[0m\e[22m│\e[22m\e[0m                                          \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[0m\e[22m│\e[22m\e[0m                                          \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[0m\e[22m│\e[22m\e[0m                                          \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[22m╰───────────────────────────────────       \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[22m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\e[22m\e[0m"

    p = Panel(
        PlaceHolder(60, 30);
        width = 49,
        height = 22,
        box = :HEAVY,
        justify = :center,
        title = "description",
        title_justify = :center,
        title_style = "bold bright_blue",
        padding = (2, 0, 2, 0),
        fit = false,
    )
    @test p.measure.w == 49
    @test p.measure.h == 22
    # @test string(p) == "\e[22m┏━━━━━━━━━━━━━━━━━\e[22m \e[1m\e[38;5;12mdescription\e[22m\e[39m\e[22m ━━━━━━━━━━━━━━━━━┓\e[22m\e[39m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m                                               \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[" ⋯ 623 bytes ⋯ "╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ \e[22m\e[1m           \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲  \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m    \e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲   \e[0m\e[22m┃\e[22m\e[0m\n\e[0m\e[22m┃\e[22m\e[0m             \e[2m... content omitted ...\e[22m           \e[0m\e[22m┃\e[22m\e[0m\n\e[22m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\e[22m\e[0m"
end

@testset "\e[34mPanel + renderables" begin
    testpanel(Panel(RenderableText("x" .^ 5)), 11, 3)

    testpanel(Panel(RenderableText("x" .^ 500); fit = false), 88, 9)

    testpanel(Panel(RenderableText("x" .^ 5); fit = true), 11, 3)

    testpanel(
        Panel(RenderableText("x" .^ 500); fit = true),
        displaysize(stdout)[2],
        nothing,
    )
end

@testset "\e[34mPANEL - titles" begin
    style="red"
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

            testpanel(
                Panel(
                    Panel(
                        "."^50;
                        title = "test",
                        title_style = style,
                        title_justify = justify,
                        subtitle = "subtest",
                        subtitle_style = style,
                        subtitle_justify = justify,
                        fit = fit,
                    );
                    fit = fit,
                ),
                fit ? nothing : 88,
                5,
            )
        end
    end
end

@testset "\e[34mPanel - padding" begin
    p = Panel("."^24; padding = (4, 4, 2, 2), fit = false)
    testpanel(p, 88, 7)
    # @test string(p) == "\e[22m╭──────────────────────────────────────────────────────────────────────────────────────╮\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m│\e[22m    ........................                                                          \e[22m│\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m"

    p = Panel("."^24; padding = (4, 4, 2, 2), fit = true)
    testpanel(p, 34, 7)
end
