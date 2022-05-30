import Term.Renderables: Renderable
import Term.Layout: pad, PlaceHolder

import Term:
    RenderableText,
    Spacer,
    vLine,
    hLine,
    cleantext,
    textlen,
    chars,
    Panel,
    vstack,
    center!,
    leftalign!,
    rightalign!,
    leftalign,
    center,
    rightalign,
    lvstack,
    cvstack,
    rvstack

@testset "Layout - pad" begin
    @test pad("aaa", 20, :left) == "aaa                 "
    @test pad("aaa", 20, :right) == "                 aaa"
    @test pad("aaa", 20, :center) == "        aaa         "
    @test pad("aaa", 10, 20) == "          aaa                    "

    p = Panel(; width = 20, height = 10)
    pad!(p, 20, 20)
    @test p isa Panel
    @test p.measure.w == 60
    @test p.measure.h == 10

    p = Panel(; width = 20, height = 10)
    pad!(p; width = 30)
    @test p isa Panel
    @test p.measure.w == 30
    @test p.measure.h == 10
end

@testset "Layout - vertical pad" begin
    @test vertical_pad("ab", 5, :top) == "ab\n  \n  \n  \n  "
    @test vertical_pad("ab", 5, :bottom) == "  \n  \n  \n  \nab"
    @test vertical_pad("ab", 5, :center) == "  \n  \nab\n  \n  "

    @test vertical_pad("ab", 5, 5) == "  \n  \n  \n  \n  \nab\n  \n  \n  \n  \n  "

    p = Panel(; width = 20, height = 10)
    @test string(vertical_pad(p, 4, 4)) ==
        "                    \n                    \n                    \n                    \n\e[22m╭──────────────────╮\e[22m\n\e[22m│\e[22m                  \e[22m│\e[22m\n\e[22m│\e[22m                  \e[22m│\e[22m\n\e[22m│\e[22m                  \e[22m│\e[22m\n\e[22m│\e[22m                  \e[22m│\e[22m\n\e[22m│\e[22m                  \e[22m│\e[22m\n\e[22m│\e[22m                  \e[22m│\e[22m\n\e[22m│\e[22m                  \e[22m│\e[22m\n\e[22m│\e[22m                  \e[22m│\e[22m\n\e[22m╰──────────────────╯\e[22m\e[0m\n                    \n                    \n                    \n                    "

    vertical_pad!(p, 4, 4)
    @test p isa Panel
    @test p.measure.w == 20
    @test p.measure.h == 18

    p = Panel(; width = 20, height = 10)
    vertical_pad!(p; height = 30)
    @test p isa Panel
    @test p.measure.w == 20
    @test p.measure.h == 30
end

@testset "\e[34mlayout - spacer" begin
    sizes = [(22, 1), (44, 123), (21, 1), (4334, 232)]
    for (w, h) in sizes
        spacer = Spacer(w, h)
        @test spacer.measure.w == w
        @test spacer.measure.h == h
    end
end

@testset "\e[34mlayout - justification" begin
    function make_panels()
        begin
            return (Panel(; width = 5), Panel(; width = 10), Panel(; width = 15))
        end
    end

    # right justify
    p1, p2, p3 = make_panels()

    rightalign!(p1, p2, p3)
    @test p1 isa Panel
    @test p1.measure.w == p2.measure.w == p3.measure.w

    # right justify
    p1, p2, p3 = make_panels()

    center!(p1, p2, p3)
    @test p1 isa Panel
    @test p1.measure.w == p2.measure.w == p3.measure.w

    # right justify
    p1, p2, p3 = make_panels()
    leftalign!(p1, p2, p3)
    @test p1 isa Panel
    @test p1.measure.w == p2.measure.w == p3.measure.w

    # convenience functions
    p1, p2, p3 = make_panels()
    pp = lvstack(p1, p2, p3)
    @test pp isa Renderable
    @test pp.measure.w == 15
    @test string(pp) ==
        "\e[22m╭───╮\e[22m          \n\e[22m╰───╯\e[22m\e[0m          \n\e[22m╭────────╮\e[22m     \n\e[22m╰────────╯\e[22m\e[0m     \n\e[22m╭─────────────╮\e[22m\n\e[22m╰─────────────╯\e[22m\e[0m"
    @test p1 isa Panel
    @test p1.measure.w == 5

    p1, p2, p3 = make_panels()
    pp = cvstack(p1, p2, p3)
    @test pp isa Renderable
    @test pp.measure.w == 15
    @test string(pp) ==
        "     \e[22m╭───╮\e[22m     \n     \e[22m╰───╯\e[22m\e[0m     \n  \e[22m╭────────╮\e[22m   \n  \e[22m╰────────╯\e[22m\e[0m   \n\e[22m╭─────────────╮\e[22m\n\e[22m╰─────────────╯\e[22m\e[0m"
    @test p1 isa Panel
    @test p1.measure.w == 5

    p1, p2, p3 = make_panels()
    pp = rvstack(p1, p2, p3)
    @test pp isa Renderable
    @test pp.measure.w == 15
    @test string(pp) ==
        "          \e[22m╭───╮\e[22m\n          \e[22m╰───╯\e[22m\e[0m\n     \e[22m╭────────╮\e[22m\n     \e[22m╰────────╯\e[22m\e[0m\n\e[22m╭─────────────╮\e[22m\n\e[22m╰─────────────╯\e[22m\e[0m"
    @test p1 isa Panel
    @test p1.measure.w == 5
end

@testset "\e[34mlayout - vLine " begin
    for h in [1, 22, 55, 11]
        line = vLine(h)
        @test length(line.segments) == h
        @test line.measure.h == h
    end

    lines = [(22, "bold"), (55, "red on_green")]
    for (h, style) in lines
        line = vLine(h; style = style)
        @test length(line.segments) == h
        @test line.measure.h == h
    end
    line = vLine(5; style = "red")
    @test line.segments[1].text == "\e[31m│\e[39m\e[0m"

    for box in (:MINIMAL_DOUBLE_HEAD, :DOUBLE, :ASCII, :DOUBLE_EDGE)
        @test vLine(22; box = box).measure.h == 22
    end

    panel = Panel(; width = 20, height = 5)
    @test length(vLine(panel).segments) == 5
    @test vLine().measure.h == displaysize(stdout)[1]
end

@testset "\e[34mlayout - hLine " begin
    for w in [1, 342, 433, 11, 22]
        line = hLine(w)
        @test length(line.segments) == 1
        @test textlen(line.segments[1].text) == w
        @test line.measure.w == w
    end

    for box in (:MINIMAL_DOUBLE_HEAD, :DOUBLE, :ASCII, :DOUBLE_EDGE)
        @test hLine(22; box = box).measure.w == 22
        @test hLine(22, "title"; box = box).measure.w == 22
    end

    for style in ("bold", "red on_green", "blue")
        @test textlen(hLine(11; style = style).segments[1].text) == 11
        @test textlen(hLine(11, "ttl"; style = style).segments[1].text) == 11
    end

    panel = Panel(; width = 20, height = 5)
    @test hLine().measure.w == displaysize(stdout)[2]
    @test textlen(hLine(panel).segments[1].text) == 20
end

@testset "\e[34mlayout - stack strings" begin
    s1 = "."^50
    s2 = ".\n"^5 * "."
    @test s1 / s2 isa String
end

function testlayout(p, w, h)
    _p = string(p)
    widths = textwidth.(cleantext.(split(_p, "\n")))
    @test length(unique(widths)) == 1

    @test p.measure.w == w
    @test textlen(cleantext(p.segments[1].text)) == w
    @test length(chars(cleantext(p.segments[1].text))) == w

    @test p.measure.h == h
    @test length(p.segments) == h
end

@testset "\e[34mlayout - renderable" begin
    r1 = RenderableText("."^100; width = 25)
    r2 = RenderableText("."^100; width = 50)

    r = r1 / r2
    @test r.measure.w == 50
    @test r.measure.h == 6

    h1 = hLine(22)
    h2 = hLine(33)
    @test (h1 / h2).measure.w == 33
    @test (h1 / h2).measure.h == 2

    r1 = RenderableText("."^100; width = 25)
    r2 = RenderableText("."^100; width = 50)

    r = r1 * r2
    @test r.measure.w == 75
    @test r.measure.h == 4

    # stack other renderables
    h1 = vLine(22)
    h2 = vLine(33)
    @test (h1 * h2).measure.w == 2
    @test (h1 * h2).measure.h == 33
end

@testset "\e[34mlayout - panels" begin
    p1 = Panel()
    p2 = Panel(; width = 24, height = 3)
    p3 = Panel("this {red}panel{/red}"^5; width = 12)

    testlayout(p1 * p2, 112, 3)
    @test string(p1 * p2) ==
        "\e[22m╭──────────────────────────────────────────────────────────────────────────────────────╮\e[22m\e[22m╭──────────────────────╮\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m\e[22m│\e[22m                      \e[22m│\e[22m\n                                                                                        \e[22m╰──────────────────────╯\e[22m\e[0m"

    testlayout(p1 / p2, 88, 5)
    @test string(p1 / p2) ==
        "\e[22m╭──────────────────────────────────────────────────────────────────────────────────────╮\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[0m\n\e[22m╭──────────────────────╮\e[22m                                                                \n\e[22m│\e[22m                      \e[22m│\e[22m                                                                \n\e[22m╰──────────────────────╯\e[22m\e[0m                                                                "

    testlayout(p2 * p1, 112, 3)
    testlayout(p2 / p1, 88, 5)

    testlayout(p1 * p2 * p3, 124, 11)
    testlayout(p1 / p2 / p3, 88, 16)
    testlayout(p3 * p1 * p2, 124, 11)
    testlayout(p3 / p1 / p2, 88, 16)
end

@testset "\e[34mlayout - placeholder" begin
    ph = PlaceHolder(4, 2)
    @test length(ph.segments) == 2
    @test ph.measure.w == 4
    @test ph.measure.h == 2
    @test string(ph) == "\e[2m ╲ ╲\e[22m\n\e[2m╲ ╲ \e[22m"

    @test string(PlaceHolder(25, 12)) ==
        "\e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲\e[22m\n\e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ \e[22m\n\e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲\e[22m\n\e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ \e[22m\n\e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲\e[22m\n\e[2m╲ ╲ ╲ ╲\e[22m\e[1m\e[37m(25 × 12)\e[22m\e[22m\e[39m\e[2m╲ ╲ ╲ ╲ \e[22m\n\e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲\e[22m\n\e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ \e[22m\n\e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲\e[22m\n\e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ \e[22m\n\e[2m ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲\e[22m\n\e[2m╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ ╲ \e[22m"

    p = Panel(; width = 8, height = 4)
    ph = PlaceHolder(p)
    @test ph.measure.w == p.measure.w
    @test ph.measure.h == p.measure.h
end
