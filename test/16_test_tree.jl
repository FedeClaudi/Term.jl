import Term: Tree, TERM_THEME, LightTheme
import OrderedCollections: OrderedDict

trees = [
    Dict(
        "nestedasdasdsadasdasdsadsadasdasdasdsadasasdasdassfsdfdsfdsfdsfsdfsdfdsfsdfd" =>
            Dict("n1" => 1, "n2" => 2),
    ),
    Dict("nested" => Dict("n1" => 1, "n2" => 2), "nested2" => Dict("n1" => "a", "n2" => 2)),
    Dict(
        "nested" => Dict("n1" => 1, "n2" => 2),
        "leaf2" => 2,
        "leaf" => 2,
        "leafme" => "v",
        "canopy" => "test",
        ["a"] => :test,
    ),
    Dict(
        "nested" => Dict(
            "deeper" => Dict("aleaf" => "unbeliefable", "leaflet" => "level 3"^20),
            "n2" => Int,
            "n3" => 1 + 2,
        ),
        "nested2" => Dict("n1" => "a", "n2" => 2),
    ),
    Dict(
        "nested" => Dict(
            "deeper" => Dict(
                "aleaf" => "unbeliefable",
                "leaflet" => "level 3",
                "sodeep" => Dict("a" => 4),
            ),
            "n2" => Int,
            "n3" => 1 + 2,
            "adict" => Dict("x" => 2),
        ),
        "nested2" => Dict("n1" => "a", "n2" => 2),
    ),
    OrderedDict(3 => OrderedDict(3 => 8, 1 => "a"), 2 => OrderedDict(3 => 8, 1 => "a")),
    OrderedDict(2 => 1, 3 => OrderedDict(4 => 2, "a" => 2, "b" => 1)),
    [1, 2, [2, 3, 4]],
    [
        1,
        [2, [3, 4], "a"^200],
        :c,
        OrderedDict(2 => "a", 1 => :ok, "a" => 2, :test => [1, 2]),
    ],
    Int,
    String,
    :(print, :(x, y)),
]

@testset "\e[34mTree" begin
    thm1 = TERM_THEME[]
    thm2 = LightTheme

    for (i, theme) in enumerate((thm1, thm2))
        for (j, guides_type) in enumerate((:standardtree, :boldtree, :asciitree))
            for (k, tree) in enumerate(trees)
                if VERSION ≥ v"1.7"  # ! not sure why but this fails in older versions: segmentation fault
                    IS_WIN || @compare_to_string string(
                        Tree(
                            tree;
                            theme = theme,
                            guides = guides_type,
                            printkeys = true,
                            title = "tree_$(i)_$(j)_$(k)",
                        ),
                    ) "tree_$(i)_$(j)_$(k)"
                end
            end
        end
    end

    # test with no errors
    @test_nothrow Tree(Float64)
    @test_nothrow Tree(AbstractFloat)

    # test printing
    @test sprint(io -> show(io, Tree(trees[1]))) ==
          "\e[38;5;117mTree <: AbstractRenderable\e[0m \e[2m(h:10, w:80)\e[0m"
    @test sprint(io -> show(io, MIME("text/plain"), Tree(trees[1]).segments[1])) ==
          "Segment{String} \e[2m(size: Measure (h: 1, w: 80))\e[0m"
end
