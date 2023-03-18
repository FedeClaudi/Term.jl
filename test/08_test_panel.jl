import Term: Panel, TextBox, apply_style, default_width, str_trunc
import Term.Layout: PlaceHolder

@testset "\e[34mPanel - no content" begin
    @test size(Panel(height = 4, width = 10)) == (4, 10)

    for style in ("default", "red", "on_blue")
        @testpanel(Panel(fit = true, style = style), 2, 3)
        @testpanel(Panel(), 3, TEST_CONSOLE_WIDTH)
        @testpanel(Panel(height = 4, width = 12, style = style), 4, 12)
    end
end

@testset "\e[34mPanel - basic shape" begin
    @testpanel(Panel("MYTEXT"; height = 10, width = 60), 10, 60)
    @testpanel(Panel("MYTEXT"; width = 60), 3, 60)
    @testpanel(Panel("MYTEXT"), 3, TEST_CONSOLE_WIDTH)
    @testpanel(Panel("MYTEXT", fit = true), 3, 12)

    @testpanel(Panel("MYTEXT"; height = 10, width = 60, padding = (4, 4, 2, 2)), 10, 60)
    @testpanel(Panel("MYTEXT"; width = 60, padding = (4, 4, 2, 2)), 7, 60)
    @testpanel(Panel("MYTEXT"; padding = (4, 4, 2, 2)), 7, TEST_CONSOLE_WIDTH)
    @testpanel(Panel("MYTEXT"; padding = (4, 4, 2, 2), fit = true), 7, 16)
end

@testset "\e[34mPanel - fit overflow" begin
    inside = Panel("MYTEXT"^50; height = 10)
    @testpanel(inside, 10, 80)
    @testpanel(Panel(inside / inside, fit = true), 42, TEST_CONSOLE_WIDTH,)
    @testpanel(Panel(inside / inside, fit = false), 42, TEST_CONSOLE_WIDTH,)
end

@testset "\e[34mPANEL - fit - measure" begin
    for style in ("default", "red", "on_blue")
        # ----------------------------- text only content ---------------------------- #
        _kw = (fit = true, style = style)
        @testpanel(Panel("t"; _kw...), 3, 7)
        @testpanel(Panel("test"; _kw...), 3, 10)
        @testpanel(Panel("1234\n123456789012"; _kw...), 4, 18)
        @testpanel(Panel("나랏말싸미 듕귁에 달아"; _kw...), 3, 28)
        @testpanel(Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; _kw...), 4, 28)
        @testpanel(Panel("°"^500; _kw...), 9, TEST_CONSOLE_WIDTH)

        # ------------------------------- nested panels ------------------------------ #
        @testpanel(Panel(Panel("test"; _kw...); _kw...), 5, 16)

        @testpanel(
            Panel(Panel(Panel("°"; _kw...); _kw...); fit = true, style = style),
            7,
            19,
        )
    end
end

@testset "\e[34mPANEL - nofit - measure" begin
    for style in ("default", "red", "on_blue")
        @testpanel(Panel("t"; style = style, fit = false), 3, TEST_CONSOLE_WIDTH)
        @testpanel(Panel("test"; style = style, fit = false), 3, TEST_CONSOLE_WIDTH)
        @testpanel(
            Panel("1234\n123456789012"; style = style, fit = false),
            4,
            TEST_CONSOLE_WIDTH
        )
        @testpanel(Panel("나랏말싸미 듕귁에 달아"; style = style, fit = false), 3, TEST_CONSOLE_WIDTH)
        @testpanel(
            Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; style = style, fit = false),
            4,
            TEST_CONSOLE_WIDTH,
        )
        for justify in (:left, :center, :right)
            # ----------------------------- text only content ---------------------------- #
            _kw = (justify = justify, style = style)
            _nofit = (; fit = false, _kw...)
            @testpanel(Panel("°"^1500; _nofit...), 23, TEST_CONSOLE_WIDTH)

            # ------------------------------- nested panels ------------------------------ #
            @testpanel(Panel(Panel("test", fit = true); _nofit...), 5, TEST_CONSOLE_WIDTH)

            # @testpanel(Panel(Panel(Panel("°", fit=true); _nofit...); _nofit...), nothing, TEST_CONSOLE_WIDTH)

            # NOTE: using a panel with arbitrary long text can fail testing on wide terminals, since
            # the final `height` can vary (github.com/FedeClaudi/Term.jl/issues/112)
            @testpanel(Panel(Panel("°"^250); _nofit...), 14, TEST_CONSOLE_WIDTH)

            @testpanel(
                Panel(Panel("test"; _kw...); fit = false),
                nothing,
                TEST_CONSOLE_WIDTH
            )

            @testpanel(
                Panel(
                    Panel("t1"; fit = true, _kw...),
                    Panel("t2"; fit = true, _kw...);
                    fit = false,
                ),
                8,
                TEST_CONSOLE_WIDTH
            )

            @testpanel(
                Panel(
                    [Panel("t1"; fit = true, _kw...), Panel("t2"; fit = true, _kw...)];
                    fit = false,
                ),
                8,
                TEST_CONSOLE_WIDTH
            )

            _kw = (fit = false, height = 8, width = 30)
            @testpanel(Panel(Panel("test"; width = 22); _kw...), 8, 30)

            @testpanel(Panel(Panel("test"; width = 42); _kw...), 8, 30)

            @testpanel(
                Panel(
                    Panel("test"; height = 12, width = 42);
                    fit = false,
                    height = 8,
                    width = 30,
                ),
                8,
                30,
            )
        end
    end
end

@testset "\e[34mPANEL - FIT - measure" begin
    @testpanel(Panel("t"; fit = true), 3, 7)
    @testpanel(Panel("test"; fit = true), 3, 10)
    @testpanel(Panel("1234\n123456789012"; fit = true), 4, 18)
    @testpanel(Panel("나랏말싸미 듕귁에 달아"; fit = true), 3, 28)
    @testpanel(Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; fit = true), 4, 28)
    for justify in (:left, :center, :right)
        # ----------------------------- text only content ---------------------------- #
        _kw = (fit = true, justify = justify)
        @testpanel(Panel("°"^1500; _kw...), nothing, TEST_CONSOLE_WIDTH)

        # ------------------------------- nested panels ------------------------------ #
        @testpanel(Panel(Panel("test", fit = true); _kw...), 5, 16)

        @testpanel(Panel(Panel(Panel("°", fit = true); _kw...); _kw...), 7, 19)

        @testpanel(
            Panel(Panel("°"^250, fit = true); _kw...),
            # WIDE_TERM ? nothing : 8,
            14,
            TEST_CONSOLE_WIDTH
        )

        @testpanel(Panel(Panel("test"; _kw...); fit = true), 5, 16)

        @testpanel(Panel(Panel(Panel("°"; _kw...); _kw...); fit = true), 7, 19,)

        @testpanel(Panel(Panel("t1"; _kw...), Panel("t2"; _kw...); fit = true), 8, 14,)

        _kw = (fit = true, width = 30, height = 8)
        @testpanel(Panel(Panel("test"; width = 22); _kw...), 8, 28)

        @testpanel(Panel(Panel("test"; width = 42); _kw...), 8, 48)

        @testpanel(Panel(Panel("test"; height = 12, width = 42); _kw...), 14, 48)
    end
end

@testset "PANEL - centered title style" begin
    for (i, just) in enumerate([:left, :center, :right])
        p = Panel(
            title = "test",
            width = 40,
            title_justify = just,
            title_style = "italic red",
        )
        @testpanel(p, nothing, 40)
        IS_WIN || @compare_to_string(p, "centered_title_panel_$(i)")

        p = Panel(title = "test", width = 50, title_justify = just)
        IS_WIN || @compare_to_string(p, "centered_title_panel_$(i+3)")
        @testpanel(p, nothing, 50)
    end

    p = Panel(
        title = "test",
        title_justify = :left,
        subtitle = "aaaaa",
        subtitle_justify = :right,
        width = 22,
    )
    IS_WIN || @compare_to_string(p, "centered_titile_panel_7")
end

@testset "PANEL - small panel with title" begin
    for (i, w) in enumerate((5, 9, 10, 11, 12, 13, 14, 15))
        for (j, title) in enumerate(("aa", "aaaa", "aaaaaa", "adadasdoajdoaidjaldad"))
            for (k, just) in enumerate([:left, :center, :right])
                p = Panel(;
                    width = w,
                    title = title,
                    title_justify = just,
                    style = "hidden",
                )
                IS_WIN || @compare_to_string(p, "small_panel_title_$(i)_$(j)_$(k)")
            end
        end
    end
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

    @testpanel(Panel(pts2; fit = false, width = 44), nothing, 44)
    @testpanel(Panel(pts2; fit = false, width = 51), nothing, 51)
    @testpanel(Panel(pts2; fit = false, width = 67), nothing, 67)

    circle = """
          oooo    
       oooooooooo 
      oooooooooooo
      oooooooooooo
       oooooooooo 
          oooo    """
    p = Panel(circle; fit = true, padding = (2, 2, 0, 0))
    @test string(p) ==
          "\e[0m\e[22m╭────────────────╮\e[22m\e[0m\n\e[22m│\e[22m      oooo      \e[22m│\e[22m\n\e[22m│\e[22m   oooooooooo   \e[22m│\e[22m\n\e[22m│\e[22m  oooooooooooo  \e[22m│\e[22m\n\e[22m│\e[22m  oooooooooooo  \e[22m│\e[22m\n\e[22m│\e[22m   oooooooooo   \e[22m│\e[22m\n\e[22m│\e[22m      oooo      \e[22m│\e[22m\n\e[0m\e[22m╰────────────────╯\e[22m\e[0m\e[0m"

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

@testset "\e[34mPANEL - titles" begin
    style = "red"
    for fit in (true, false)
        for justify in (:left, :center, :right)
            @testpanel(
                Panel(
                    "°"^50;
                    title = "test",
                    title_style = style,
                    title_justify = justify,
                    subtitle = "subtest",
                    subtitle_style = style,
                    subtitle_justify = justify,
                    fit = fit,
                ),
                3,
                fit ? nothing : default_width(),
            )
        end
    end
end

@testset "\e[34mPanel - padding" begin
    p = Panel("°"^24; padding = (4, 4, 2, 2), fit = false)
    @testpanel(p, 7, default_width())

    p = Panel("°"^24; padding = (4, 4, 2, 2), fit = true)
    @testpanel(p, 7, 34)
end

@testset "\e[34mPanel - background" begin
    p = Panel(
        RenderableText(
            "testste";
            style = "white on_red",
            background = "on_blue",
            width = 25,
        );
        background = "green",
    )
    IS_WIN || @compare_to_string p "panel_background_1"

    p = Panel(apply_style(
        """
    asasd
asdasadas
asdsasdasdsadasdsa
ads
    """,
        "on_blue",
    ); background = "on_red", fit = true)

    IS_WIN || @compare_to_string p "panel_background_2"
end

@testset "\e[34mPANEL - UnicodePlots" begin
    # using UnicodePlots; pl = lineplot(1:2; padding=0, margin=0); str = UnicodePlots.no_ansi_escape(string(pl))
    str = """
     ┌────────────────────────────────────────┐
    2│⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠊│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠁⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠊⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠊⠁⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⠀⠀⢀⡠⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     │⠀⠀⠀⡠⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
    1│⣀⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
     └────────────────────────────────────────┘
     ⠀1⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀2⠀"""
    p = Panel(str; fit = true, style = "hidden")
    @test Term.remove_ansi(string(p)) == """
    ╭───────────────────────────────────────────╮
    │ ┌────────────────────────────────────────┐│
    │2│⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠊││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠁⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠊⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠊⠁⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⠀⠀⢀⡠⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ │⠀⠀⠀⡠⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │1│⣀⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀││
    │ └────────────────────────────────────────┘│
    │ ⠀1⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀2⠀│
    ╰───────────────────────────────────────────╯"""
end

@testset "\e[34mPANEL - nested panels macro" begin
    pns = @nested_panels Panel(
        Panel("inner", Panel("out", Panel("deep")); style = "green"),
        Panel("inner2 "^25; height = 5),
        "test",
        RenderableText("adasdasda"),
        Panel(; style = "red on_black");
        height = 20,
        style = "red",
    )

    IS_WIN || @compare_to_string(pns, "panels_layout_macro")

    pns = @nested_panels Panel(
        Panel(Panel()),
        Panel(Panel("red"); style = "red on_black"),
        Panel(),
        Panel(; style = "red"),
        "done";
        height = 20,
        style = "red",
    )

    IS_WIN || @compare_to_string(pns, "panels_layout_macro2")

    pns = @nested_panels Panel()
    IS_WIN || @compare_to_string(pns, "panels_layout_macro3")

    pns = @nested_panels Panel(Panel())
    IS_WIN || @compare_to_string(pns, "panels_layout_macro4")

    pns = @nested_panels Panel(Panel("a"), Panel("b"))
    IS_WIN || @compare_to_string(pns, "panels_layout_macro5")

    pns = @nested_panels Panel(Panel("a"), Panel("b"; style = "green"); style = "red")
    IS_WIN || @compare_to_string(pns, "panels_layout_macro6")
end

@testset "PANEL - constructors" begin
    p1, p2 = Panel(; width = 5), Panel(; width = 8)
    p = Panel([p1, p2])
    IS_WIN || @compare_to_string(string(p), "panels_constructors_1")

    p = Panel(string.([p1, p2]))
    IS_WIN || @compare_to_string(string(p), "panels_constructors_2")
end
