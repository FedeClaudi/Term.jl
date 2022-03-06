import Term: Measure
import Term: remove_markup

@testset "\e[31mMeasure - str" begin
    @test Measure("a"^10).w == 10

    strings = (
        "asadasda"^2,
        "~~±±||__ASdaSDvxcvxc\nasdfsiaudfhsdiufhndskjv",
        "dasdadsa\nsdfsd"^7,
        "asdasdsa|dfvcxvashfusdn\nfidsuhfsdf"
    )
    for string in strings
        m = Measure(string)
        @test m.w == lw(string)
        @test m.h == nlines(string)
    end

    strings = (
        "[red]is my color"^2,
        "~~±±||__[red on_green]aasdas[bold]asdsad[/bold]asdas[/red on_green]xc\nasdfsiaudfhsdiufhndskjv",
        "dasda[#ffffff]dsa[#ffffff]\nsdfsd"^7,
        "asdasdsa|dfvcxvashf[bold]usdn\nfid[/bold]suhfsdf"
    )
    for string in strings
        m = Measure(string)
        @test m.w == lw(remove_markup(string))
        @test m.h == nlines(remove_markup(string))
    end

end