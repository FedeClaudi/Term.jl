using Term.Links
import Term.Layout: pad

clean_link(l) = sprint(print, l) |> remove_ansi |> remove_markup

file = "/Users/federicoclaudi/Documents/Github/Term.jl/src/_tables.jl"
lineno = 234

l1 = Link(file)
l2 = Link(file, lineno)
l3 = Link(file, lineno; style = "red")

ren = RenderableText("abcd")
lr = RenderableText(l2 * ren)

@testset "LINK measure" begin
    @test l1.measure.w == 25
    @test l2.measure.w == 29
    @test l3.measure.w == 29

    ren_w = ren.measure.w
    @test (l1 * ren).measure.w == 25 + ren_w
    @test (l2 * ren).measure.w == 29 + ren_w
    @test (l3 * ren).measure.w == 29 + ren_w

    @test lr.measure.w == 33
    @test (lr * ren).measure.w == 37

    @test (l1 / l2).measure.w == 29
    @test (l1 / lr).measure.w == 33
end

@testset "LINK padding" begin
    for (ln, link) in enumerate((l1, l2, l3))
        for (j, met) in enumerate([:left, :center, :right])
            ll = pad(link; width = 80, method = :left)
            @test ll.measure.w == 80
            IS_WIN && @compare_to_string(ll, "link_pad_$(ln)_$j")
        end
    end
end

@testset "LINK and panel" begin
    for (ln, link) in enumerate((l1, l2, l3))
        for (i, fit) in enumerate([true, false])
            p0 = Panel(link; fit = fit)
            p1 = Panel(link / ren; fit = fit)
            p2 = Panel(link * ren; fit = fit)
            p3 = Panel(link; width = 50)
            p4 = Panel(link, p3; fit = fit)

            for (j, p) in enumerate([p0, p1, p2, p3, p4])
                IS_WIN && @compare_to_string(p, "link_panel_$(ln)_$(i)_$(j)")
            end
        end
    end
end
