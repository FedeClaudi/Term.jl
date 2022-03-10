import Term: Panel, TextBox, cleantext

function testpanel(p, w, h)
    # check all lines have the same length
    _p = string(p)
    widths = textwidth.(cleantext.(split(_p, "\n")))
    # @test length(unique(widths)) == 1

    # check it has the right measure
    @test p.measure.w == w
    @test p.measure.h == h

end

@testset "\e[34mPANEL - size" begin
    for justify in (:left, :center, :right)
        p = Panel(; justify=justify)
        testpanel(p, 2, 3)

        p = Panel("1234567890"; justify=justify)
        testpanel(p, 12, 3)
        
        p = Panel("나랏말싸미 듕귁에 달아"; justify=justify)
        testpanel(p, 24, 3)

        p = Panel("[red]test[/red]"; justify=justify)
        testpanel(p, 6, 3)

        p = Panel(;width=50, height=5, fit=:nofit, justify=justify)
        testpanel(p, 50, 5)

        p = Panel(;width=5000, height=5, fit=:nofit, justify=justify)
        @test p.measure.w < 5000

        p = Panel("t\ne\ns\nt";width=1050, height=5, justify=justify)
        testpanel(p, 3, 6)

        p = Panel("t\ne\nsssss\nt";width=1050, height=5, justify=justify)
        testpanel(p, 7, 6)

        p = Panel("t\ne\nsssss\nt";width=50, height=5, fit=:nofit, justify=justify)
        testpanel(p, 50, 5)

        p = Panel("t\ne\nsssss\nt";width=50, height=5, fit=:center, justify=justify)
        testpanel(p, 50, 5)
    end
end


@testset "\e[34mTBox meaasure" begin
    tb1 = TextBox(
        "nofit"
    )
    println(tb1.measure.w, tb1.measure.w == 88)
    @test tb1.measure.h == 3
    @test tb1.measure.w == 88

    # check that unreasonable widhts are ignored
    tb2 = TextBox(
        "nofit"^25;
        width=1000
    )
    @test tb1.measure.w <= 1000

    tb3 = TextBox(
        "truncate"^25;
        width=100,
        fit=:truncate
    )
    @test tb3.measure.w == 100
    @test tb3.measure.h == 3

    tb4 = TextBox(
        "truncate"^25;
        width=100,
    )
    @test tb4.measure.w == 100
    @test tb4.measure.h >= 5

    tb5 = TextBox(
        "truncate"^25;
        fit=:fit
    )
    @test tb5.measure.w == 204
    @test tb5.measure.h >= 3
end


# @testset "\e[34mPanel - panel creation" begin
#     p1 = Panel("this panel has fixed width"; width = 44, justify = :right)
#     @test string(p1) ==
#         "╭──────────────────────────────────────────╮\n│               this panel has fixed width │\n╰──────────────────────────────────────────╯"

#     p2 = Panel(
#         "this one too, but the text is at the center!"; width = 66, justify = :center
#     )
#     @test string(p2) ==
#         "╭────────────────────────────────────────────────────────────────╮\n│          this one too, but the text is at the center!          │\n╰────────────────────────────────────────────────────────────────╯"

#     p3 = Panel("this one fits its content"; width = :fit)
#     @test string(p3) ==
#         "╭───────────────────────────╮\n│ this one fits its content │\n╰───────────────────────────╯"

#     p4 = Panel(
#         "[red]This is the panel's first line.[/red]",
#         "[bold green]and this is another, panel just stacks all inputs into one piece of content[/bold green]";
#         width = :fit,
#     )
#     @test string(p4) ==
#         "╭─────────────────────────────────────────────────────────────────────────────╮\n│ \e[31mThis is the panel's first line.\e[39m                                             │\n│ \e[1m\e[32mand this is another, panel just stacks all inputs into one piece of content\e[22m\e[39m │\n╰─────────────────────────────────────────────────────────────────────────────╯"

#     p5 = Panel(
#         "content "^10;
#         subtitle = "another panel",
#         subtitle_style = "dim underline",
#         subtitle_justify = :right,
#         width = 44,
#     )
#     @test string(p5) ==
#         "╭──────────────────────────────────────────╮\n│ content content content content content  │\n│ content content content content content  │\n╰─────────────────────────\e[0m \e[2m\e[4manother panel\e[22m\e[24m ──╯"

#     p6 = Panel("content "^10; box = :DOUBLE, style = "blue", width = 44)
#     @test string(p6) ==
#         "\e[34m╔══════════════════════════════════════════╗\e[39m\n\e[34m║\e[39m content content content content content  \e[34m║\e[39m\n\e[34m║\e[39m content content content content content  \e[34m║\e[39m\n\e[34m╚══════════════════════════════════════════╝\e[39m"

#     # test with wider chars
#     p7 = Panel("나랏말싸미 듕귁에 달아")
#     p8 = Panel("こんにちは(わ)")

#     @test p7.measure.w == 26
#     @test p8.measure.w == 18
#     @test p8.measure.h == 3

#     @test string(p7) ==
#         "╭────────────────────────╮\n│ 나랏말싸미 듕귁에 달아 │\n╰────────────────────────╯"
#     @test string(p8) == "╭────────────────╮\n│ こんにちは(わ) │\n╰────────────────╯"

#     # create empty panels with varying size
#     p9 = Panel(; height = 20, width = 4)
#     p10 = Panel(""; height = 5)
#     p11 = Panel(; width = 12, height = 6)

#     # check all  lines in each panel have exactly the same size
#     for panel in (p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11)
#         _p = string(panel)
#         widths = textwidth.(cleantext.(split(_p, "\n")))
#         @test length(unique(widths)) == 1
#     end
# end

# @testset "\e[34mPanel - panel layout  " begin
#     pright = Panel(
#         "content [red]with style[/red] "^26;
#         title = "My Panel",
#         title_style = "bold red",
#         width = 44,
#     )
#     pleft = Panel("content "^30; box = :DOUBLE, style = "blue", width = 66)
#     pp = Panel(
#         pleft / pright;
#         style = "green dim",
#         title_style = "green",
#         title = "vertically stacked!",
#         title_justify = :center,
#         subtitle = "styled by Term.jl",
#         subtitle_justify = :right,
#         subtitle_style = "dim",
#         justify = :center,
#     )

#     @test pright.measure.w == 44
#     @test pright.measure.h == 15

#     @test pleft.measure.w == 66
#     @test pleft.measure.h == 6

#     @test pp.measure.w == 70
#     @test pp.measure.h == 23

#     pv = pright / pleft
#     @test pv.measure.w == 66
#     @test pv.measure.h == 21

#     ph = pright * pleft
#     @test ph.measure.w == 110
#     @test ph.measure.h == 15
# end

# @testset "\e[34mPanel - tbox creation " begin
#     my_long_text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
#     tb = TextBox(my_long_text; width = 44)

#     @test tb.measure.w == 44
#     @test tb.measure.h == 14
#     @test string(tb) ==
#         "\e[8m╭──────────────────────────────────────────╮\e[28m\n\e[8m│\e[28m Lorem ipsum dolor sit amet, consectetur  \e[8m│\e[28m\n\e[8m│\e[28m adipiscing elit, sed do eiusmod tempor i \e[8m│\e[28m\n\e[8m│\e[28m ncididunt ut labore et dolore magna aliq \e[8m│\e[28m\n\e[8m│\e[28m ua. Ut enim ad minim veniam, quis nostru \e[8m│\e[28m\n\e[8m│\e[28m d exercitation ullamco laboris nisi ut a \e[8m│\e[28m\n\e[8m│\e[28m liquip ex ea commodo consequat. Duis aut \e[8m│\e[28m\n\e[8m│\e[28m e irure dolor in reprehenderit in volupt \e[8m│\e[28m\n\e[8m│\e[28m ate velit esse cillum dolore eu fugiat n \e[8m│\e[28m\n\e[8m│\e[28m ulla pariatur. Excepteur sint occaecat c \e[8m│\e[28m\n\e[8m│\e[28m upidatat non proident, sunt in culpa qui \e[8m│\e[28m\n\e[8m│\e[28m officia deserunt mollit anim id est lab  \e[8m│\e[28m\n\e[8m│\e[28m orum.                                    \e[8m│\e[28m\n\e[8m╰──────────────────────────────────────────╯\e[28m"

#     tb2 = TextBox(
#         my_long_text;
#         title = "This is my long text",
#         title_style = "bold red",
#         title_justify = :center,
#         subtitle = "styled by Term.jl",
#         subtitle_justify = :right,
#         subtitle_style = "dim",
#         width = 88,
#     )
#     @test string(tb2) ==
#         "\e[8m╭────────────────────────────────\e[28m\e[0m \e[1m\e[31mThis is my long text\e[22m\e[39m \e[8m────────────────────────────────╮\e[28m\n\e[8m│\e[28m Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incid \e[8m│\e[28m\n\e[8m│\e[28m idunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exerci \e[8m│\e[28m\n\e[8m│\e[28m tation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolo \e[8m│\e[28m\n\e[8m│\e[28m r in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. E \e[8m│\e[28m\n\e[8m│\e[28m xcepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mo \e[8m│\e[28m\n\e[8m│\e[28m llit anim id est laborum.                                                            \e[8m│\e[28m\n\e[8m╰─────────────────────────────────────────────────────────────────\e[28m\e[8m\e[0m \e[2mstyled by Term.jl\e[22m \e[8m──╯\e[28m\e[28m"
# end

# @testset "\e[34mPanel - tbox markup  " begin
#     another_long_one =
#         "This is a [red bold]very[/red bold] piece of [green italic]content[/green italic]. But TextBox can handle [underline]anything[/underline]!! "^10
#     tb = TextBox(another_long_one; width = 44)

#     @test tb.measure.w == 44
#     @test tb.measure.h == 19

#     @test string(tb) ==
#         "\e[8m╭──────────────────────────────────────────╮\e[28m\n\e[8m│\e[28m This is a \e[1m\e[31mvery\e[22m\e[39m piece of \e[3m\e[32mcontent\e[23m\e[39m. But Tex \e[8m│\e[28m\n\e[8m│\e[28m tBox can handle \e[4manything\e[24m!! This is a \e[1m\e[31mver\e[22m\e[39m \e[8m│\e[28m\n\e[8m│\e[28m \e[1m\e[31my\e[22m\e[39m piece of \e[3m\e[32mcontent\e[23m\e[39m. But TextBox can hand \e[8m│\e[28m\n\e[8m│\e[28m le \e[4manything\e[24m!! This is a \e[1m\e[31mvery\e[22m\e[39m piece of \e[3m\e[32mco\e[23m\e[39m \e[8m│\e[28m\n\e[8m│\e[28m \e[3m\e[32mntent\e[23m\e[39m. But TextBox can handle \e[4manything\e[24m!! \e[8m│\e[28m\n\e[8m│\e[28m This is a \e[1m\e[31mvery\e[22m\e[39m piece of \e[3m\e[32mcontent\e[23m\e[39m. But Te  \e[8m│\e[28m\n\e[8m│\e[28m xtBox can handle \e[4manything\e[24m!! This is a \e[1m\e[31mve\e[22m\e[39m \e[8m│\e[28m\n\e[8m│\e[28m \e[1m\e[31mry\e[22m\e[39m piece of \e[3m\e[32mcontent\e[23m\e[39m. But TextBox can han \e[8m│\e[28m\n\e[8m│\e[28m dle \e[4manything\e[24m!! This is a \e[1m\e[31mvery\e[22m\e[39m piece of \e[3m\e[32mc\e[23m\e[39m \e[8m│\e[28m\n\e[8m│\e[28m \e[3m\e[32montent\e[23m\e[39m. But TextBox can handle \e[4manything\e[24m! \e[8m│\e[28m\n\e[8m│\e[28m ! This is a \e[1m\e[31mvery\e[22m\e[39m piece of \e[3m\e[32mcontent\e[23m\e[39m. But T \e[8m│\e[28m\n\e[8m│\e[28m extBox can handle \e[4manything\e[24m!! This is a \e[1m\e[31mv\e[22m\e[39m \e[8m│\e[28m\n\e[8m│\e[28m \e[1m\e[31mery\e[22m\e[39m piece of \e[3m\e[32mcontent\e[23m\e[39m. But TextBox can ha \e[8m│\e[28m\n\e[8m│\e[28m ndle \e[4manything\e[24m!! This is a \e[1m\e[31mvery\e[22m\e[39m piece of  \e[8m│\e[28m\n\e[8m│\e[28m \e[3m\e[32mcontent\e[23m\e[39m. But TextBox can handle \e[4manything\e[24m \e[8m│\e[28m\n\e[8m│\e[28m \e[4m\e[24m!! This is a \e[1m\e[31mvery\e[22m\e[39m piece of \e[3m\e[32mcontent\e[23m\e[39m. But  \e[8m│\e[28m\n\e[8m│\e[28m TextBox can handle \e[4manything\e[24m!!            \e[8m│\e[28m\n\e[8m╰──────────────────────────────────────────╯\e[28m"
# end


# @testset "\r[34mPanel measure" begin
#     p = Panel()
#     @test p.measure.w == 2
#     @test p.measure.h == 2

#     p = Panel("test")
#     @test p.measure.w == 6
#     @test p.measure.h == 3

#     p = Panel("test"^100; width=100, fit=:nofit)
#     @test p.measure.w == 100
#     @test p.measure.h == 5

#     p = Panel("."^50; width=25, height=10, fit=:nofit)
#     @test p.measure.w == 25
#     @test p.measure.h == 10
# end

