import Term.dendogram: link, Dendogram

@testset "DENDOGRAM" begin
    mydendo = Dendogram("awesome", "this", :is, "a", "dendogram!")
    otherdendo = Dendogram("head", "these", "are", "colorful",  "leaves")
    smalldendo = Dendogram("head", [1, 2])

    @test string(mydendo) == "                     \e[38;2;255;171;145mawesome\e[39m                      \n\e[1m\e[2m\e[38;2;144;202;249m     ┌────────────┬──────┴─────┬────────────┐     \e[22m\e[22m\e[39m\n\e[38;2;176;190;197m   this          is            a       dendogram! \e[39m"

    large = link(mydendo, otherdendo; title="{red}superdendo{/red}")
    @test string(large) == "                                             \e[38;2;255;171;145m\e[31msuperdendo\e[39m\e[38;2;255;171;145m\e[39m                                             \n\e[1m\e[2m\e[38;2;144;202;249m                         ┌────────────────────────┴───────────────────────┐                         \e[22m\e[22m\e[39m\n                     \e[38;2;255;171;145mawesome\e[39m                                             \e[38;2;255;171;145mhead\e[39m                       \n\e[1m\e[2m\e[38;2;144;202;249m     ┌────────────┬──────┴─────┬────────────┐     \e[22m\e[22m\e[39m\e[1m\e[2m\e[38;2;144;202;249m     ┌────────────┬──────┴─────┬────────────┐     \e[22m\e[22m\e[39m\n\e[38;2;176;190;197m   this          is            a       dendogram! \e[39m\e[38;2;176;190;197m   these         are       colorful      leaves   \e[39m"

    # nested = link(smalldendo, link(smalldendo, link(smalldendo, smalldendo; title="a level"); title="another level"); title="first level")
    # @test string(nested) == fromfile("./txtfiles/dendogram_nested.txt")
end