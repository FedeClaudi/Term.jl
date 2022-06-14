import Term: Theme, set_theme

@testset "\e[34mtheme" begin
    io = PipeBuffer()
    show(io, MIME("text/plain"), Theme())  # coverage
    @test read(io, String) isa String

    theme = TERM_THEME[]
    @test set_theme(theme) == theme
end
