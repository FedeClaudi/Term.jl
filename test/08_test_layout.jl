import Term: RenderableText, Spacer, vLine, hLine, cleantext, textlen, chars

@testset "\e[34mlayout - spacer" begin
    sizes = [(22, 1), (44, 123), (21, 1), (4334, 232)]
    for (w, h) in sizes
        spacer = Spacer(w, h)
        @test spacer.measure.w == w
        @test spacer.measure.h == h
    end
end

@testset "\e[34mlayout - vLine " begin
    for h in [1, 22, 55, 11]
        line = vLine(h)
        @test length(line.segments) == h
        @test line.measure.h == h
        @test line.height == h
    end

    lines = [(22, "bold"), (55, "red on_green")]
    for (h, style) in lines
        @test vLine(h; style = style).measure.h == h
    end

    for box in (:MINIMAL_DOUBLE_HEAD, :DOUBLE, :ASCII, :DOUBLE_EDGE)
        @test vLine(22; box = box).height == 22
    end

    @test vLine().height == displaysize(stdout)[1]
end

@testset "\e[34mlayout - hLine " begin
    for w in [1, 342, 433, 11, 22]
        line = hLine(w)
        @test line.width == w
        @test length(line.segments) == 1
        @test line.measure.w == w
    end

    for box in (:MINIMAL_DOUBLE_HEAD, :DOUBLE, :ASCII, :DOUBLE_EDGE)
        @test hLine(22; box = box).width == 22
        @test hLine(22, "title"; box = box).width == 22
    end

    for style in ("bold", "red on_green", "blue")
        @test hLine(11; style = style).width == 11
        @test hLine(11, "ttl"; style = style).width == 11
    end

    @test hLine().width == displaysize(stdout)[2]
end


@testset "\e[34mlayout - stack strings" begin
    s1 = "."^50
    s2 = ".\n"^5 * "."
    r = s1 / s2
    @test r.measure.w == 50
    @test r.measure.h == 7

    s1 = "."^50
    s2 = "[red][bold blue].[/bold blue][/red]\n"^5 * "."
    r = s1 / s2
    @test r.measure.w == 50
    @test r.measure.h == 7
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
    p2 = Panel(; width=24, height=3)
    p3 = Panel("test[red]aajjaja[/red]"^5, width=12)

    testlayout(p1 * p2, 112, 3)
    @test string(p1 * p2) == "\e[22m╭──────────────────────────────────────────────────────────────────────────────────────╮\e[22m\e[22m╭──────────────────────╮\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[22m│\e[22m                      \e[22m│\e[22m\n                                                                                        \e[22m╰──────────────────────╯\e[22m"


    testlayout(p1 / p2, 88, 5)
    @test string(p1 / p2) == "\e[22m╭──────────────────────────────────────────────────────────────────────────────────────╮\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\n\e[22m╭──────────────────────╮\e[22m                                                                \n\e[22m│\e[22m                      \e[22m│\e[22m                                                                \n\e[22m╰──────────────────────╯\e[22m                                                                "

    testlayout(p2 * p1, 112, 3)
    testlayout(p2 / p1, 88, 5)

    testlayout(p1 * p2 * p3, 124, 12)
    testlayout(p1 / p2 / p3, 88, 17)
    testlayout(p3 * p1 * p2, 124, 12)
    testlayout(p3 / p1 / p2, 88, 17)     
end