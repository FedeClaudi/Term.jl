import Term: Theme

@testset "\e[34mtheme" begin
    show(devnull, Theme())  # coverage
    @test true
end

# TODO: write more tests
