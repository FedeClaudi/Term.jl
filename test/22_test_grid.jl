import Term.Measures: default_size
import Term.Layout: PlaceHolder
import Term: Renderable, AbstractRenderable

@testset "Grid - simple" begin
    h, w = default_size()
    n = 3
    nm1 = n - 1
    lo = (n, n)

    @test size(grid(layout = lo).measure) == (h * n, w * n)
    @test size(grid(layout = lo, pad = 2).measure) == (h * n + 2nm1, w * n + 2nm1)
    @test size(grid(layout = lo, pad = (5, 1)).measure) == (h * n + 1nm1, w * n + 5nm1)
    @test size(grid(layout = lo, pad = (5, 3)).measure) == (h * n + 3nm1, w * n + 5nm1)
    @test size(grid(layout = lo, pad = (0, 0)).measure) == (h * n, w * n)

    # test passing renderables
    h, w = 5, 10
    rens = fill(PlaceHolder(h, w), 9)

    @test size(grid(rens).measure) == (3h, 3w)
    @test size(grid(rens; aspect = 1).measure) == (3h, 3w)

    @test size(grid(rens[1:8]; aspect = 0.5).measure) == (4h, 2w)
    @test size(grid(rens[1:8]; aspect = 2).measure) == (2h, 4w)

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

    @test grid(Any[Panel(width = 10 + i) for i in 1:4]) isa AbstractRenderable

    # matrix, fold singletons
    @test grid([Panel() Panel()]) isa AbstractRenderable
    @test grid(reshape([Panel()], 1, 1)) isa AbstractRenderable
end

@testset "Grid - placeholders" begin
    nr, nc = 3, 2
    h, w = 5, 15
    g = grid(nothing; layout = (nr, nc), placeholder_size = (h, w))
    @test size(g.measure) == (nr * h, nc * w)

    g = grid(; layout = (nr, nc), placeholder_size = (h, w))
    @test size(g.measure) == (nr * h, nc * w)
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
    @test size(grid(reshape(panels[1:4], 2, 2)).measure) == (2h, 2w)

    # vector, half explicit
    @test size(grid(panels, layout = (nothing, 4)).measure) == (2h, 4w)
    @test size(grid(panels, layout = (2, nothing)).measure) == (2h, 4w)

    # vector, explicit
    @test size(grid(panels; layout = (2, 4)).measure) == (2h, 4w)
    @test size(grid(panels; layout = (2, 4), order = :row).measure) == (2h, 4w)

    # best fit
    panels = fill(Panel(height = h, width = w), 9)

    @test size(grid(panels[1:4]).measure) == (2h, 2w)  # 4 best fits onto a (2, 2) grid with unit ar
    @test size(grid(panels[1:6]).measure) == (2h, 3w)  # 6 best fits onto a (2, 3) grid with 4:3 ar
    @test size(grid(panels[1:9]).measure) == (3h, 3w)  # 9 best fits onto a (3, 3) grid with unit ar
end

@testset "Grid - types" begin
    @test grid((a = Panel(), b = Panel())) isa Renderable
    @test grid((Panel(), Panel())) isa Renderable
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

    # named tuple
    g = grid((a = rens[1], b = rens[2]); layout = :((_ * a) / (b * _)))
    @test size(g.measure) == (10, 25)
end
