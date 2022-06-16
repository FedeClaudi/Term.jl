@testset "Grid - simple" begin
    w, h = default_size()
    n = 3
    nm1 = n - 1

    @test size(grid(layout = (n, n), pad = (0, 0)).measure) == (w * n, h * n)

    @test size(grid(layout = (n, n)).measure) == (w * n, h * n)

    @test size(grid(layout = (n, n), pad = 2).measure) == (w * n + 2 * nm1, h * n + 2 * nm1)

    @test size(grid(layout = (n, n), pad = (5, 1)).measure) ==
          (w * n + 5 * nm1, h * n + 1 * nm1)

    @test size(grid(layout = (n, n), pad = (5, 3)).measure) ==
          (w * n + 5 * nm1, h * n + 3 * nm1)

    # test passing renderables

    w, h = 10, 5
    rens = repeat([PlaceHolder(w, h)], 9)

    @test size(grid(rens; aspect = 1).measure) == (3w, 3h)

    @test size(grid(rens).measure) == (3w, 3h)

    @test size(grid(rens; pad = (2, 1)).measure) == (3w + 2 * 2, 3h + 2 * 1)

    @test size(grid(rens; pad = (2, 1), aspect = 0.5).measure) == (22, 29)

    @test size(grid(rens; pad = (2, 1), aspect = 1.5).measure) == (46, 17)

    g = grid(
        rens;
        pad = (2, 1),
        aspect = (12, 12),
        placeholder = PlaceHolder(10, 5; style = "red"),
    )
    @test size(g.measure) == (34, 17)
end

@testset "Grid - layout fit" begin
    w, h = 20, 10
    panels = collect(
        Panel("{on_$c} {/on_$c}", width = w, height = h) for c in (
            :bright_red,
            :bright_green,
            :bright_blue,
            :bright_yellow,
            :bright_magenta,
            :bright_cyan,
            :bright_black,
            :bright_white,
        )
    )

    # auto layout (default placeholder)
    for i in 2:length(panels)
        g = grid(panels[1:i])
        nc, nr = if i ≤ 3
            (i, 1)
        else
            (ceil(Int, i / 2), 2)
        end
        @test size(g.measure) == (w * nc, h * nr)
    end

    # matrix, explicit
    grid(reshape(panels[1:4], 2, 2))

    # vector, half explicit
    grid(panels, layout = (nothing, 4))
    grid(panels, layout = (2, nothing))

    # vector, explicit
    grid(panels; layout = (2, 4))

    # best fit
    panels = [Panel(width = w, height = h) for _ in 1:9]

    @test size(grid(panels[1:4]).measure) == (2w, 2h)  # 4 best fits onto a (2, 2) grid with unit ar
    @test size(grid(panels[1:6]).measure) == (3w, 2h)  # 6 best fits onto a (3, 2) grid with 4:3 ar
    @test size(grid(panels[1:9]).measure) == (3w, 3h)  # 9 best fits onto a (3, 3) grid with unit ar
end

@testset "Grid - complex layout" begin
    w, h = 20, 10
    p = Panel(width = w, height = w)
    g = grid(repeat([p], 5), layout = :((_ * □) / (□ * _ * □) / (□ * □)))
    @test size(g).measure == (3w, 3h)
end
