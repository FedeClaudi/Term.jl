import Term: Panel, TextBox, cleantext, textlen, chars



@testset "\e[34mPanel - no content" begin
    for style in ("default", "red", "on_blue")
        testpanel(
            Panel(;fit=true, style=style), 3, 2
        )

        testpanel(
            Panel(), 88, 2
        )

        testpanel(
            Panel(; width=12, height=4, style=style), 12, 4
        )
    end

end

@testset "\e[34mPANEL - fit - measure" begin
    for style in ("default", "red", "on_blue")
        for justify in (:left, :center, :right)
            # ----------------------------- text only content ---------------------------- #
            testpanel(
                Panel("t"; fit=true, style=style), 7, 3
            )
            testpanel(
                Panel("test"; fit=true, style=style), 10, 3
            )
            testpanel(
                Panel("1234\n123456789012"; fit=true, style=style), 18, 4
            )
            testpanel(
                Panel("나랏말싸미 듕귁에 달아"; fit=true, style=style), 28, 3
            )
            testpanel(
                Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; fit=true, style=style), 28, 4
            )
            testpanel(
                Panel("."^500; fit=true, style=style), displaysize(stdout)[2]-4, nothing
            )

            # ------------------------------- nested panels ------------------------------ #
            testpanel(
                Panel(
                    Panel("test"; fit=true, style=style);
                fit=true, style=style), 
                16, 5
            )

            testpanel(
                Panel(
                    Panel(Panel("."; fit=true, style=style); fit=true, style=style);
                fit=true, style=style), 19, 7
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
            testpanel(
                Panel("t"; style=style), 88, 3
            )
            testpanel(
                Panel("test"; style=style), 88, 3
            )
            testpanel(
                Panel("1234\n123456789012"; style=style), 88, 4
            )
            testpanel(
                Panel("나랏말싸미 듕귁에 달아"; style=style), 88, 3
            )
            testpanel(
                Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; style=style), 88, 4
            )
            testpanel(
                Panel("."^1500; style=style), 88, 21
            )

            # ------------------------------- nested panels ------------------------------ #
            testpanel(
                Panel(
                    Panel("test");
                fit=true, style=style), 94, 5
            )
            
            
            testpanel(
                Panel(
                    Panel(Panel("."); fit=true, style=style);
                fit=true, style=style), 100, 7
            )
            
            testpanel(
                Panel(
                    Panel("."^250); fit=true, style=style
                ), 94, 8
            )


            testpanel(
                Panel(
                    Panel("test"; style=style);
            ), 94, 5
            )

            testpanel(
                Panel(
                    Panel(Panel("."; style=style); style=style);
            ), 100, 7
            )

            testpanel(
                Panel(
                    Panel("."^250; style=style);
                ), 94, 8
            )

            testpanel(
                Panel(
                    Panel("t1"; style=style),
                    Panel("t2"; style=style),
                ), 94, 8
            )


            testpanel(
                Panel(
                    Panel("test", width=22);  width=30, height=8
                ), 30, 8
            )

            testpanel(
                Panel(
                    Panel("test", width=42);  width=30, height=8
                ), 48, 8
            )

            testpanel(
                Panel(
                    Panel("test", width=42,height=12);  width=30, height=8
                ), 48, 14
            )
        end
    end
end


@testset "\e[34mPanel + renderables" begin
    testpanel(
        Panel(
            RenderableText("x".^5)
        ), 88, 3
    )


    testpanel(
        Panel(
            RenderableText("x".^500)
        ), 88, nothing
    )


    testpanel(
        Panel(
            RenderableText("x".^5); fit=true
        ), 11, 3
    )

    testpanel(
        Panel(
            RenderableText("x".^500); fit=true
        ), displaysize(stdout)[2]-4, nothing
    )

end


@testset "\e[34mPANEL - titles" begin
    for fit in (true, false)
        for justify in (:left, :center, :right)
            for style in ("red", "bold", "default", "on_green")

                testpanel(
                    Panel("."^50, title="test",
                            title_style=style,
                            title_justify=justify,
                            subtitle="subtest",
                            subtitle_style=style,
                            subtitle_justify=justify,
                            fit=fit
                            ),
                    fit ? nothing : 88,
                    nothing
                )

                testpanel(
                    Panel(
                        Panel("."^50, title="test",
                                title_style=style,
                                title_justify=justify,
                                subtitle="subtest",
                                subtitle_style=style,
                                subtitle_justify=justify,
                                  fit=fit,
                                )
                    ),
                    fit ? nothing : 94,
                    nothing
                )
            end 
        end
    end
end





@testset "\e[34mTBOX" begin
    w = displaysize(stdout)[2]

    for justify in (:left, :center, :right)


        testpanel(
            TextBox(
                "nofit"^25;
                width=1000,
                justify=justify
            ),w, nothing)

        testpanel(
            TextBox(
                "truncate"^25;
                width=100,
                fit=:truncate,
                justify=justify
        ), 100, 4)

        testpanel(
            TextBox(
                "truncate"^25;
                width=100,
                justify=justify
            ), 100, 7)

        testpanel(
            TextBox(
                "truncate"^8;
                fit=:fit,
                justify=justify
            ), 68, 4)

        testpanel(
            TextBox(
                "[red]truncate[/red]"^8;
                fit=:fit,
                justify=justify
            ), 68, 4)

        # testpanel(
        #     TextBox(
        #         "[red]tru\nncate[/red]test"^8;
        #         fit=:fit,
        #         justify=justify
        #     ), 16, 11)

        testpanel(TextBox(
                "[red]tru\nncate[/red]test"^1;
                fit=:fit,
                justify=justify
            ), 13, 6)
    end
end


@testset "\e[34mPanel - padding" begin
    
    p = Panel("."^24; padding = [4, 4, 2, 2])
    testpanel(p, 88, 7)
    # @test string(p) == "\e[22m╭──────────────────────────────────────────────────────────────────────────────────────╮\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m│\e[22m    ........................                                                          \e[22m│\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m│\e[22m                                                                                      \e[22m│\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m"

    p = Panel("."^24; padding = [4, 4, 2, 2], fit=true)
    testpanel(p, 34, 7)


end