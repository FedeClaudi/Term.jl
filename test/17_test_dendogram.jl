import Term.Dendograms: link, Dendogram

@testset "DENDOGRAM" begin
    mydendo = Dendogram("awesome", "this", :is, "a", "dendogram!")
    otherdendo = Dendogram("head", "these", "are", "colorful", "leaves")
    smalldendo = Dendogram("head", [1, 2])

    IS_WIN || begin
        @compare_to_string(mydendo, "dendogram_1")
    end

    large = link(mydendo, otherdendo; title = "{red}superdendo{/red}")
    IS_WIN || begin
        @compare_to_string(large, "dendogram_2")
    end

    nested = link(
        smalldendo,
        link(
            smalldendo,
            link(smalldendo, smalldendo; title = "a level");
            title = "another level",
        );
        title = "first level",
    )
    IS_WIN || begin
        @compare_to_string(nested, "dendogram_3")
    end

    D = link(mydendo, mydendo, mydendo)
    @test D.measure.w == 150
end
