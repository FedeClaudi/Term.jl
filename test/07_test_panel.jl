import Term: Panel, TextBox

@testset "\e[34mPanel - no content" begin
    for style in ("default", "red", "on_blue")
        testpanel(Panel(; fit = true, style = style), 3, 2)

        testpanel(Panel(), 88, 2)

        testpanel(Panel(; width = 12, height = 4, style = style), 12, 4)
    end
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
            testpanel(Panel("t"; style = style), 88, 3)
            testpanel(Panel("test"; style = style), 88, 3)
            testpanel(Panel("1234\n123456789012"; style = style), 88, 4)
            testpanel(Panel("나랏말싸미 듕귁에 달아"; style = style), 88, 3)
            testpanel(Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; style = style), 88, 4)
            testpanel(Panel("."^1500; style = style), 88, 21)

            # ------------------------------- nested panels ------------------------------ #
            testpanel(Panel(Panel("test"); fit = true, style = style), 94, 5)

            testpanel(
                Panel(
                    Panel(Panel("."); fit = true, style = style);
                    fit = true,
                    style = style,
                ),
                100,
                7,
            )

            testpanel(Panel(Panel("."^250); fit = true, style = style), 94, 8)

            testpanel(Panel(Panel("test"; style = style);), 94, 5)

            testpanel(Panel(Panel(Panel("."; style = style); style = style);), 100, 7)

            testpanel(Panel(Panel("."^250; style = style);), 94, 8)

            testpanel(Panel(Panel("t1"; style = style), Panel("t2"; style = style)), 94, 8)

            testpanel(Panel(Panel("test"; width = 22); width = 30, height = 8), 30, 8)

            testpanel(Panel(Panel("test"; width = 42); width = 30, height = 8), 48, 8)

            testpanel(
                Panel(Panel("test"; width = 42, height = 12); width = 30, height = 8),
                48,
                14,
            )
        end
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

    if dotest
        @test string(Panel(pts; style = "red", width = 44)) ==
              "\e[31m╭──────────────────────────────────────────╮\e[39m\n\e[31m│\e[39m  Lorem\e[31m ipsum dolor s\e[39mit amet, consectetu\e[0m  \e[31m│\e[39m\n\e[31m│\e[39m  r adipiscing elit,ed do eiusmod tempor\e[0m  \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34mincididu\e[4mnt ut labore et dolore magna\e[0m    \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[4maliqua. Ut enim ad minimveniam, quis\e[0m    \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[4mnos\e[24m\e[34mtrud exercitation ullamco laboris\e[0m    \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[34mnisi ut aliquip ex ea commodo consequa\e[0m  \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[34mt. Duis aute \e[31m\e[40mirure dolor in reprehende\e[0m  \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[34m\e[31m\e[40mrit in voluptate velit esse cillum\e[0m      \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[34m\e[31m\e[40mdolore eu fugiat nulla pariatur.\e[0m        \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[34m\e[31m\e[40mExcepteur sint occaecat cupidatat\e[0m       \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[34mnon proident, sunt in \e[32mculpa qui offic\e[0m   \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[34m\e[32mia deserunt mollit anim id est laborum\e[0m  \e[31m│\e[39m\n\e[31m│\e[39m  \e[1m\e[34m\e[34m\e[49m.\e[0m                                       \e[31m│\e[39m\n\e[31m╰──────────────────────────────────────────╯\e[39m\e[0m"

        @test string(Panel(pts; width = 60)) ==
              "\e[22m╭──────────────────────────────────────────────────────────╮\e[22m\n\e[22m│\e[22m  Lorem\e[31m ipsum dolor s\e[39mit amet, consectetur adipiscing\e[0m      \e[22m│\e[22m\n\e[22m│\e[22m  elit,ed do eiusmod tempor \e[1m\e[34mincididu\e[4mnt ut labore et\e[0m       \e[22m│\e[22m\n\e[22m│\e[22m  \e[1m\e[34m\e[4mdolore magna aliqua. Ut enim ad minimveniam, quis nos\e[24m\e[34m\e[0m   \e[22m│\e[22m\n\e[22m│\e[22m  \e[1m\e[34m\e[34mtrud exercitation ullamco laboris nisi ut aliquip ex\e[0m    \e[22m│\e[22m\n\e[22m│\e[22m  \e[1m\e[34m\e[34mea commodo consequat. Duis aute \e[31m\e[40mirure dolor in repreh\e[0m   \e[22m│\e[22m\n\e[22m│\e[22m  \e[1m\e[34m\e[34m\e[31m\e[40menderit in voluptate velit esse cillum dolore eu fugia\e[0m  \e[22m│\e[22m\n\e[22m│\e[22m  \e[1m\e[34m\e[34m\e[31m\e[40mt nulla pariatur. Excepteur sint occaecat cupidatat\e[0m     \e[22m│\e[22m\n\e[22m│\e[22m  \e[1m\e[34m\e[34mnon proident, sunt in \e[32mculpa qui officia deserunt\e[0m        \e[22m│\e[22m\n\e[22m│\e[22m  \e[1m\e[34m\e[34m\e[49mmollit anim id est laborum.\e[0m                             \e[22m│\e[22m\n\e[22m╰──────────────────────────────────────────────────────────╯\e[22m\e[0m"
    end

    @test string(Panel(pts2; width = 44)) ==
          "\e[22m╭──────────────────────────────────────────╮\e[22m\n\e[22m│\e[22m  Lorem ipsum \e[1mdolor sit\e[22m amet, consectetu\e[0m  \e[22m│\e[22m\n\e[22m│\e[22m  r adipiscing elit,ed do e\e[31miusmod tempor\e[0m  \e[22m│\e[22m\n\e[22m│\e[22m  \e[31mincididunt\e[39m\e[22m ut \e[1mlabore et \e[4mdolore\e[24m\e[1m magna\e[0m    \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[1maliqua.\e[22m Ut enim ad minimveniam, quis\e[32m\e[0m    \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32mnostrud exercitation \e[40mullamco laboris\e[0m    \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[40mnisi ut aliquip ex \e[49m\e[32mea commodo consequa\e[0m  \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32mt.\e[34m Duis aute irure dolor in\e[39m\e[32m reprehende\e[0m  \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[32mrit in voluptate velit\e[39m\e[22m esse \e[3mcillum\e[0m      \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3mdolore\e[23m\e[22m\e[31m eu\e[39m\e[22m\e[3m\e[32m fugiat \e[22mnulla pariatur.\e[0m        \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3m\e[32m\e[22mExcepteur\e[31m sint\e[39m\e[22m\e[34m occaecat cupidatat \e[39m\e[22mnon\e[0m   \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3m\e[32m\e[22mproident, sunt in culpa qui \e[3mofficia\e[23m\e[22m\e[0m     \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3m\e[32mdeserunt mollit anim id est laborum.\e[0m    \e[22m│\e[22m\n\e[22m╰──────────────────────────────────────────╯\e[22m\e[0m"

    @test string(Panel(pts2; width = 51)) ==
          "\e[22m╭─────────────────────────────────────────────────╮\e[22m\n\e[22m│\e[22m  Lorem ipsum \e[1mdolor sit\e[22m amet, consectetur adipi\e[0m  \e[22m│\e[22m\n\e[22m│\e[22m  scing elit,ed do e\e[31miusmod tempor incididunt\e[39m\e[22m\e[0m     \e[22m│\e[22m\n\e[22m│\e[22m  \e[22mut \e[1mlabore et \e[4mdolore\e[24m\e[1m magna aliqua.\e[22m Ut enim\e[0m      \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1mad minimveniam, quis\e[32m nostrud exercitation \e[40mul\e[0m   \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[40mlamco laboris nisi ut aliquip ex \e[49m\e[32mea commodo\e[0m    \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32mconsequat.\e[34m Duis aute irure dolor in\e[39m\e[32m reprehen\e[0m   \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[32mderit in voluptate velit\e[39m\e[22m esse \e[3mcillum dolore\e[23m\e[22m\e[31m\e[0m    \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[31meu\e[39m\e[22m\e[3m\e[32m fugiat \e[22mnulla pariatur. Excepteur\e[31m sint\e[39m\e[22m\e[34m\e[0m       \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3m\e[32m\e[34moccaecat cupidatat \e[39m\e[22mnon proident, sunt in\e[0m       \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3m\e[32m\e[22mculpa qui \e[3mofficia\e[23m\e[22m deserunt mollit anim id est\e[0m  \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3m\e[32mlaborum.\e[0m                                       \e[22m│\e[22m\n\e[22m╰─────────────────────────────────────────────────╯\e[22m\e[0m"

    @test string(Panel(pts2; width = 67)) ==
          "\e[22m╭─────────────────────────────────────────────────────────────────╮\e[22m\n\e[22m│\e[22m  Lorem ipsum \e[1mdolor sit\e[22m amet, consectetur adipiscing elit,ed\e[0m     \e[22m│\e[22m\n\e[22m│\e[22m  do e\e[31miusmod tempor incididunt\e[39m\e[22m ut \e[1mlabore et \e[4mdolore\e[24m\e[1m magna aliqu\e[0m   \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[1ma.\e[22m Ut enim ad minimveniam, quis\e[32m nostrud exercitation \e[40mullamco\e[0m   \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[40mlaboris nisi ut aliquip ex \e[49m\e[32mea commodo consequat.\e[34m Duis aute\e[0m     \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[34mirure dolor in\e[39m\e[32m reprehenderit in voluptate velit\e[39m\e[22m esse \e[3mcillum\e[0m    \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3mdolore\e[23m\e[22m\e[31m eu\e[39m\e[22m\e[3m\e[32m fugiat \e[22mnulla pariatur. Excepteur\e[31m sint\e[39m\e[22m\e[34m occaecat\e[0m       \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3m\e[32m\e[34mcupidatat \e[39m\e[22mnon proident, sunt in culpa qui \e[3mofficia\e[23m\e[22m deserunt\e[0m     \e[22m│\e[22m\n\e[22m│\e[22m  \e[22m\e[1m\e[32m\e[32m\e[22m\e[3m\e[32mmollit anim id est laborum.\e[0m                                    \e[22m│\e[22m\n\e[22m╰─────────────────────────────────────────────────────────────────╯\e[22m\e[0m"
end

@testset "\e[34mPanel + renderables" begin
    testpanel(Panel(RenderableText("x" .^ 5)), 88, 3)

    testpanel(Panel(RenderableText("x" .^ 500)), 88, nothing)

    testpanel(Panel(RenderableText("x" .^ 5); fit = true), 11, 3)

    testpanel(
        Panel(RenderableText("x" .^ 500); fit = true),
        displaysize(stdout)[2],
        nothing,
    )
end

@testset "\e[34mPANEL - titles" begin
    for fit in (true, false)
        for justify in (:left, :center, :right)
            for style in ("red", "bold", "on_green")
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
                    nothing,
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
                        ),
                    ),
                    fit ? nothing : 94,
                    nothing,
                )
            end
        end
    end
end

@testset "\e[34mTBOX" begin
    w = displaysize(stdout)[2]

    for justify in (:left, :center, :right)
        testpanel(TextBox("nofit"^25; width = 1000, justify = justify), w - 4, nothing)

        testpanel(
            TextBox("truncate"^25; width = 100, fit = :truncate, justify = justify),
            100,
            3,
        )

        testpanel(TextBox("truncate"^25; width = 100, justify = justify), 100, 5)

        testpanel(TextBox("truncate"^8; fit = :fit, justify = justify), 70, 3)

        testpanel(TextBox("{red}truncate{/red}"^8; fit = :fit, justify = justify), 70, 3)

        testpanel(
            TextBox("{red}truncate{/red}test"^8; fit = :fit, justify = justify),
            102,
            3,
        )

        testpanel(
            TextBox("{red}tru\nncate{/red}test"^1; fit = :fit, justify = justify),
            15,
            4,
        )
    end
end

@testset "\e[34mPanel - padding" begin
    p = Panel("."^24; padding = (4, 4, 2, 2))
    testpanel(p, 88, 7)
    # @test string(p) == "\e[22m╭──────────────────────────────────────────────────────────────────────────────────────╮\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m│\e[22m    ........................                                                          \e[22m│\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m"

    p = Panel("."^24; padding = (4, 4, 2, 2), fit = true)
    testpanel(p, 34, 7)
end
