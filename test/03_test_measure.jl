import Term.Measures: Measure, width, height, default_size
import Term: remove_markup, Panel

@testset "\e[34mMeasure - str" begin
    @test size(Measure("a"^10)) == (1, 10)

    for string in (
        "asadasda"^2,
        "~~±±||__ASdaSDvxcvxc\nasdfsiaudfhsdiufhndskjv",
        "dasdadsa\nsdfsd"^7,
        "asdasdsa|dfvcxvashfusdn\nfidsuhfsdf",
    )
        m = Measure(string)
        @test m.h == nlines(string)
        @test m.w == lw(string)
    end

    for string in (
        "[red]is my color"^2,
        "~~±±||__{red on_green}aasdas{bold}asdsad{/bold}asdas{/red on_green}xc\nasdfsiaudfhsdiufhndskjv",
        "dasda{#ffffff}dsa{#ffffff}\nsdfsd"^7,
        "asdasdsa|dfvcxvashf{bold}usdn\nfid[/bold]suhfsdf",
    )
        m = Measure(string)
        @test m.h == nlines(remove_markup(string))
        @test m.w == lw(remove_markup(string))
    end
end

# TODO test with renderables

@testset "\e34mMeasure - funcs" begin
    @test height("test") == 1
    @test width("test") == 4

    w = h = 5
    p = Panel(width = w, height = h)
    @test height(p) == h
    @test height(string(p)) == h
    @test width(p) == w

    s = first(p.segments)
    @test height(s) == 1
    @test width(s) == w

    @test size(Measure("foo") + Measure("testing")) == (2, 7)
end

@testset "\e34mMeasure - misc" begin
    console_width() >= 88 && (@test default_size() == (33, 88))
end
