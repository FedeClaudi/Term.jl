import Term.Renderables: Renderable, RenderableText, AbstractRenderable, trim_renderable
import Term: Panel
import Term.Segments: Segment
import Term: fillin, apply_style

@testset "\e[34mSegment" begin
    seg = Segment("test", "default")
    @test seg.text == "\e[22mtest\e[22m"
    @test seg.measure.w == 4

    @test_nothrow println(seg)

    seg = Segment("test", "red")
    @test seg.text == "\e[31mtest\e[39m"
    @test seg.measure.w == 4

    seg = Segment("aa\n{blue}123{/blue}")
    @test size(seg.measure) == (2, 3)

    seg = Segment("test")
    @test seg * "test" isa Segment
    @test (seg * "t2").text == "testt2"
    @test ("t2" * seg).text == "t2test"
    @test (seg * seg).text == "testtest"

    s = @capture_out show(seg)
    @test s == string(s)
end

@testset "\e[34mRenderables - RenderableText basic" begin
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore"
    r = RenderableText(lorem)

    @test size(r.measure) == (2, TEST_CONSOLE_WIDTH)

    r2 = RenderableText(r)
    @test size(r.measure) == (2, TEST_CONSOLE_WIDTH)

    width = 22
    r = RenderableText(lorem; width = width)
    @test string(r) ==
          "Lorem ipsum dolor     \nsit amet, consectetur \n adipiscing elit,     \nsed do eiusmod tempor \n incididunt ut labore "
    @test r.measure.w == width

    r = RenderableText(lorem; width = width, style = "red")
    @test string(r) ==
          "\e[31mLorem ipsum dolor     \e[39m\n\e[31msit amet, consectetur \e[39m\n\e[31m adipiscing elit,     \e[39m\n\e[31msed do eiusmod tempor \e[39m\n\e[31m incididunt ut labore \e[39m"
    @test r.measure.w == width

    @test string(RenderableText("a string")) == "a string"
    @test string(RenderableText("a\nstring")) == "a     \nstring"

    @test_nothrow @capture_out show(r)

    @test sprint(io -> show(io, MIME("text/plain"), r)) == string(r) * "\n"
end

@testset "\e[34mRenderables - RenderableText basic" begin
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore"
    width = 30

    IS_WIN || begin
        r = RenderableText(lorem, width = width, justify = :right)
        @compare_to_string(r, "renderable_text_1")

        r = RenderableText(lorem, width = width, justify = :center, background = "on_red")
        @compare_to_string(r, "renderable_text_2")
    end
end

@testset "\e[34mRenderables - RenderableText shape" begin
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    for (i, w) in enumerate([10, 12, 15, 18, 23, 25, 60])
        t = RenderableText(lorem; width = w)
        @testpanel(t, nothing, w)
        IS_WIN || @compare_to_string(t, "rend_text_shape_$(i)")
    end
end

@testset "\e[34mRenderables - trim renderables" begin
    IS_WIN || begin
        r = trim_renderable(RenderableText("aa bb"^100), 25)
        @compare_to_string(r, "trim_renderables_1")

        r = trim_renderable(Panel("aa bb"^100), 25)
        @compare_to_string(r, "trim_renderables_2")
    end
end

@testset "Renderables reshaped text markup" begin
    txt = "{red}dasda asda dadasda{green}aadasdad{/green}dad asd ad ad ad asdad{bold}adada ad as sad ad ada{/red}ad adas sd ads {/bold}"
    IS_WIN || @compare_to_string(Panel(txt; width = 30), "reshaped_rend_with_markup_1")
    IS_WIN ||
        @compare_to_string(RenderableText(txt; width = 30), "reshaped_rend_with_markup_2")

    txt = "{(220, 180, 150)}dasda {bold}asda dadasda{dodger_blue2}aadasdad{/dodger_blue2}dad asd ad{/bold} ad ad asdad{on_(25, 55, 100)}adada ad as sad ad ada{/(220, 180, 150)}ad adas sd ads {/on_(25, 55, 100)} NOW SIMPLE {red} adasd aads a asd ads a{/red} dasiudh asjdnasdiuasda {underline} asdnaisudnadaiuda sjduiabdiabd aduas {/underline}"
    IS_WIN || @compare_to_string(Panel(txt; width = 30), "reshaped_rend_with_markup_3")
    IS_WIN ||
        @compare_to_string(RenderableText(txt; width = 30), "reshaped_rend_with_markup_4")

    txt = "{(220, 180, 150)}dasda {bold}asda dadasda{dodger_blue2}aadasdad{/dodger_blue2}dad asd ad{/bold} ad ad asdad{on_(25, 55, 100)}adada ad as sad ad ada{/(220, 180, 150)}ad adas sd ads {/on_(25, 55, 100)} NOW SIMPLE {red} adasd aads a asd ads a{/red} dasiudh asjdnasdiuasda {underline} asdnaisudnadaiuda sjduiabdiabd aduas {/underline}"
    IS_WIN || @compare_to_string(
        Panel(apply_style(txt); width = 30),
        "reshaped_rend_with_markup_5"
    )
    IS_WIN || @compare_to_string(
        RenderableText(apply_style(txt); width = 30),
        "reshaped_rend_with_markup_6"
    )
end
