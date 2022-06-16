import Term.Measures: default_size
import Term.Layout: PlaceHolder

@testset "Grid - simple" begin
    h, w = default_size()
    n = 3
    nm1 = n - 1
    lo = (n, n)

    @test size(grid(layout = lo, pad = (0, 0)).measure) == (h * n, w * n)

    @test size(grid(layout = lo).measure) == (h * n, w * n)

    @test size(grid(layout = lo, pad = 2).measure) == (h * n + 2nm1, w * n + 2nm1)

    @test size(grid(layout = lo, pad = (5, 1)).measure) == (h * n + 1nm1, w * n + 5nm1)

    @test size(grid(layout = lo, pad = (5, 3)).measure) == (h * n + 3nm1, w * n + 5nm1)

    # test passing renderables

    h, w = 5, 10
    rens = repeat([PlaceHolder(h, w)], 9)

    @test size(grid(rens; aspect = 1).measure) == (3h, 3w)

    @test size(grid(rens).measure) == (3h, 3w)

    @test size(grid(rens; pad = (2, 1)).measure) == (3h + 2 * 1, 3w + 2 * 2)

    @test size(grid(rens; pad = (2, 1), aspect = 0.5).measure) == (29, 22)

    @test size(grid(rens; pad = (2, 1), aspect = 1.5).measure) == (17, 46)

    g = grid(
        rens;
        pad = (2, 1),
        aspect = (12, 12),
        placeholder = PlaceHolder(5, 10; style = "red"),
    )
    @test size(g.measure) == (17, 34)
end

@testset "Grid - layout fit" begin
    h, w = 10, 20
    panels = collect(
        Panel("{on_$c} {/on_$c}", height = h, width = w) for c in (
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
        @test size(g.measure) == (h * nr, w * nc)
    end

    # matrix, explicit
    grid(reshape(panels[1:4], 2, 2))

    # vector, half explicit
    grid(panels, layout = (nothing, 4))
    grid(panels, layout = (2, nothing))

    # vector, explicit
    grid(panels; layout = (2, 4))

    # best fit
    panels = repeat([Panel(height = h, width = w)], 9)

    @test size(grid(panels[1:4]).measure) == (2h, 2w)  # 4 best fits onto a (2, 2) grid with unit ar
    @test size(grid(panels[1:6]).measure) == (2h, 3w)  # 6 best fits onto a (2, 3) grid with 4:3 ar
    @test size(grid(panels[1:9]).measure) == (3h, 3w)  # 9 best fits onto a (3, 3) grid with unit ar
end

@testset "Grid - complex layout" begin
    rens = [
        Panel(height = 5, width = 10),
        Panel(height = 5, width = 15),
        Panel(height = 5, width = 20),
        Panel(height = 10, width = 20),
        Panel(height = 15, width = 20),
    ]
    g = grid(rens, layout = :((_ * a) / (b * _ * c) / (d * e)))
    @test size(g.measure) == (25, 45)

    # repeated in layout
    g = grid(rens, layout = :((_ * a) / (b * _ * c * c) / (d * e)))
    @test size(g.measure) == (25, 65)
end
