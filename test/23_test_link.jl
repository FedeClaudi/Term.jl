using Term.Links

@testset "LINK" begin
    file = "/Users/federicoclaudi/Documents/Github/Term.jl/src/_tables.jl"
    lineno = 234

    l1 = Link(file)
    l2 = Link(file, lineno)
    l3 = Link(file, lineno; style="red")

    ren = RenderableText("abcd")
    lr = RenderableText(link*ren)
    # TODO test

    # TODO check measure of each

    # TOOD check string represetntaion

    """
        TODO for each

            - turn into a Renderable textlen
            - hstack, vstack with string and renderables and get size
            - pad, vpad and get size
            - Panel(link)
            - Panel(link * text)
            - Panel(link / text)
            - Table([link1, link2, text])

    use: sprint(print, link) |> remove_ansi |> remove_markup to get displayed text
    """
    for (ln, link) in enumerate((l1, l2, l3))
        for (i, fit) in enumerate([true, false])
            p0 = Panel(link; fit=fit)
            p1 = Panel(link/ren; fit=fit) 
            p2 = Panel(link*ren; fit=fit)
            # TODO test stuff
        end

        for (j, met) in enumerate([:left, :center, :right])
            ll = pad(link; width=80, method=:left)
            # TODO test stuff
        end
    end
end