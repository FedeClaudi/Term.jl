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
        p = Panel(; justify=justify, fit=:fit)
        testpanel(p, 2, 3)

        p = Panel("1234567890"; justify=justify)
        testpanel(p, 88, 3)
        
        p = Panel("나랏말싸미 듕귁에 달아"; justify=justify)
        testpanel(p, 88, 3)

        p = Panel("나랏말싸미 듕귁에 달아"; fit=:fit, justify=justify)
        testpanel(p, 24, 3)

        p = Panel("[red]test[/red]"; justify=justify)
        testpanel(p, 88, 3)

        p = Panel("[red]test[/red]"; fit=:fit, justify=justify)
        testpanel(p, 6, 3)

        p = Panel(;width=50, height=5, fit=:fit)
        testpanel(p, 2, 3)

        p = Panel(;width=50, height=5)
        testpanel(p, 50, 7)

        p = Panel(;width=5000, height=5, fit=:nofit, justify=justify)
        @test p.measure.w < 5000

        p = Panel("t\ne\ns\nt";width=1050, height=5, justify=justify, fit=:fit)
        testpanel(p, 3, 6)

        p = Panel("t\ne\nsssss\nt";width=1050, height=5, justify=justify, fit=:fit)
        testpanel(p, 7, 6)

        p = Panel("t\ne\nsssss\nt";width=50, height=5, fit=:nofit, justify=justify)
        testpanel(p, 50, 7)

        p = Panel("t\ne\nsssss\nt";width=50, height=5, fit=:center, justify=justify)
        testpanel(p, 50, 7)
    end
end


@testset "\e[34mTBox meaasure" begin
    tb1 = TextBox(
        "nofit"
    )
    @test tb1.measure.h == 3
    @test tb1.measure.w == 88

    # # check that unreasonable widhts are ignored
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

