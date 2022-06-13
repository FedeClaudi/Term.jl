import Term.Colors:
    is_named_color,
    is_rgb_color,
    is_hex_color,
    is_color,
    is_background,
    get_color,
    NamedColor,
    RGBColor,
    BitColor

@testset "\e[34mANSI detect color" begin
    for name in ["red", "blue", "black", "grey42", "deep_sky_blue3", "dark_blue"]
        @test is_named_color(name)
        @test is_color(name)
        @test !is_rgb_color(name)
        @test !is_hex_color(name)
    end

    for name in ["255", "1", "21", "6", "128"]
        @test is_named_color(name)
        @test is_color(name)
        @test !is_rgb_color(name)
        @test !is_hex_color(name)
    end

    rgbs = ["(1, .8, .0)", "(.2,.1,.33)", "(.5,0.1, .99)", "(255, 128,128)", "(128,58,200)"]
    for rgb in rgbs
        @test is_rgb_color(rgb)
        @test is_color(rgb)
        @test !is_hex_color(rgb)
        @test !is_named_color(rgb)
    end

    hexes = ["#ffffff", "#000000", "#dadada", "#123123"]
    for hex in hexes
        @test is_hex_color(hex)
        @test is_color(hex)
        @test !is_named_color(hex)
        @test !is_rgb_color(hex)
    end
end

@testset "\e[34mANSI get color" begin
    for name in ["red", "blue", "black"]
        @test get_color(name) isa NamedColor
    end

    for name in ["255", "1", "21", "6", "128", "grey42", "deep_sky_blue3", "dark_blue"]
        @test get_color(name) isa BitColor
    end

    for rgb in
        ["(1, .8, .0)", "(.2,.1,.33)", "(.5,0.1, .99)", "(255, 128,128)", "(128,58,200)"]
        @test get_color(rgb) isa RGBColor
    end

    hexes = ["#ffffff", "#000000", "#dada1a", "#123123"]
    for hex in hexes
        @test get_color(hex) isa RGBColor
    end
end

@testset "\e[34mANSI background color" begin
    for name in ["on_red", "on_blue", "on_black"]
        @test is_background(name)
        @test !is_color(name)
        @test get_color(name; bg = true) isa NamedColor
    end

    for name in ["on_255", "on_1", "on_21", "on_6", "on_128"]
        @test is_background(name)
        @test !is_color(name)
        @test get_color(name; bg = true) isa BitColor
    end

    for rgb in [
        "on_(1, .8, .0)",
        "on_(.2,.1,.33)",
        "on_(.5,0.1, .99)",
        "on_(255, 128,128)",
        "on_(128,58,200)",
    ]
        @test is_background(rgb)
        @test !is_color(rgb)
        @test get_color(rgb; bg = true) isa RGBColor
    end

    hexes = ["on_#ffffff", "on_#000000", "on_#dada2a", "on_#123123"]
    for hex in hexes
        @test is_background(hex)
        @test get_color(hex; bg = true) isa RGBColor
    end
end
