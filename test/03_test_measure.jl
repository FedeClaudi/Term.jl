import Term.Measures: Measure, width, height, default_size
import Term: remove_markup, Panel

@testset "\e[34mMeasure - str" begin
    @test size(Measure("a"^10)) == (10, 1)

    for string in (
        "asadasda"^2,
        "~~±±||__ASdaSDvxcvxc\nasdfsiaudfhsdiufhndskjv",
        "dasdadsa\nsdfsd"^7,
        "asdasdsa|dfvcxvashfusdn\nfidsuhfsdf",
    )
        m = Measure(string)
        @test m.w == lw(string)
        @test m.h == nlines(string)
    end

    for string in (
        "[red]is my color"^2,
        "~~±±||__{red on_green}aasdas{bold}asdsad{/bold}asdas{/red on_green}xc\nasdfsiaudfhsdiufhndskjv",
        "dasda{#ffffff}dsa{#ffffff}\nsdfsd"^7,
        "asdasdsa|dfvcxvashf{bold}usdn\nfid[/bold]suhfsdf",
    )
        m = Measure(string)
        @test m.w == lw(remove_markup(string))
        @test m.h == nlines(remove_markup(string))
    end
end

# TODO test with renderables

@testset "\e34mMeasure - funcs" begin
    @test width("test") == 4
    @test height("test") == 1

    w = h = 5
    p = Panel(width = w, height = h)
    @test width(p) == w
    @test height(p) == h

    s = first(p.segments)
    @test width(s) == w
    @test height(s) == 1
end

@testset "\e34mMeasure - misc" begin
    @test default_size() == (88, 66)
end
