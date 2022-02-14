import Term.color: is_named_color, is_rgb_color, is_hex_color, is_color, is_background
import Term.color: get_color, RGBColor, NamedColor, RGBColor, BitColor




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


# @testset "Get color" begin
#     for name in ["red", "blue", "black"]
#         @test typeof(get_color(name)) == NamedColor
#     end


#     for name in ["255", "1", "21", "6", "128"]
#         @test typeof(get_color(name)) == BitColor
#     end


#     rgbs = [
#         "(1, .8, .0)",
#         "(.2,.1,.33)",
#         "(.5,0.1, .99)",
#         "(255, 128,128)",
#         "(128,58,200)",
#     ]
#     for rgb in rgbs
#         @test typeof(get_color(rgb)) == RGBColor
#     end


#     hexes = [
#         "#ffffff",
#         "#000000",
#         "#dadasa",
#         "#123123",
#     ]
#     for hex in hexes
#         @test typeof(get_color(hex)) == RGBColor
#     end


# end





@testset "BG color identification" begin
    for name in ["on_red", "on_blue", "on_black"]
        @test is_background(name) == true
        @test typeof(get_color(name; bg=true)) == NamedColor
    end


    for name in ["on_255", "on_1", "on_21", "on_6", "on_128"]
        @test is_background(name) == true
        @test typeof(get_color(name; bg=true)) == BitColor
    end


    rgbs = [
        "on_(1, .8, .0)",
        "on_(.2,.1,.33)",
        "on_(.5,0.1, .99)",
        "on_(255, 128,128)",
        "on_(128,58,200)",
    ]
    for rgb in rgbs
        @test is_background(rgb) == true
        @test typeof(get_color(rgb; bg=true)) == RGBColor
    end


    # hexes = [
    #     "on_#ffffff",
    #     "on_#000000",
    #     "on_#dadasa",
    #     "on_#123123",
    # ]
    # for hex in hexes
    #     @test is_background(hex) == true
    #     @test typeof(get_color(hex; bg=true)) == 
    # end
end