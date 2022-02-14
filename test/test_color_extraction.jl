import Term.color: is_named_color, is_rgb_color, is_hex_color, is_color, is_background
import Term.color: get_color




@testset "Color identification" begin
    for name in ["red", "blue", "black"]
        @test is_named_color(name) == true
        @test is_color(name) == true
    end


    for name in ["255", "1", "21", "6", "128"]
        @test is_named_color(name) == true
        @test is_color(name) == true
    end


    rgbs = [
        "(1, .8, .0)",
        "(.2,.1,.33)",
        "(.5,0.1, .99)",
        "(255, 128,128)",
        "(128,58,200)",
    ]
    for rgb in rgbs
        @test is_rgb_color(rgb) == true
        @test is_color(rgb) == true
    end


    hexes = [
        "#ffffff",
        "#000000",
        "#dadasa",
        "#123123",
    ]
    for hex in hexes
        @test is_hex_color(hex) == true
        @test is_color(hex) == true
    end
end