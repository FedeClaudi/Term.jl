module color

import Term: NAMED_COLORS, nospaces, COLORS_16b, remove_brackets, ANSICode, int, CODES, CODES_16BIT_COLORS

export NamedColor, BitColor, RGBColor, get_color


# ----------------------------- types definition ----------------------------- #
"""
    AbstractColor

Abstract color type.
"""
abstract type AbstractColor end

Base.show(io::IO, color::AbstractColor) = print(io, "$(typeof(color))('$(color.color)')")

struct NamedColor <: AbstractColor
    color::String
end

struct BitColor <: AbstractColor
    color::String
end

struct RGBColor <: AbstractColor
    r::Int
    g::Int
    b::Int
end



function RGBColor(s::String)
    to_number(x) = '.' ∈ x ? parse(Float64, x) : parse(Int, x)
    r, g, b = to_number.(match(RGB_REGEX, s).captures)
    if r < 1 || g < 1 || b < 1
        r *= 255
        g *= 255
        b *= 255
    end
    return RGBColor(int(r), int(g), int(b))
end

"""
    ANSICode(color; bg::Bool=false)

Create ANSI tags for colors.
"""
function ANSICode(color::NamedColor; bg::Bool = false)
    Δ = bg ? 40 : 30
    v = CODES[color.color]
    return ANSICode("\e[$(Δ + v)m", "\e[$(Δ+9)m")
end

function ANSICode(color::BitColor; bg::Bool = false)
    Δ = bg ? 48 : 38
    v = CODES_16BIT_COLORS[color.color]
    return ANSICode("\e[$Δ;5;$(v)m", "\e[$(Δ+1)m")
end

function ANSICode(color::RGBColor; bg::Bool = false)
        Δ = bg ? 48 : 38
        rgb = "$(color.r);$(color.g);$(color.b)"
        return ANSICode("\e[$Δ;2;$(rgb)m", "\e[$(Δ+1)m")
end



# --------------------------------- is color? -------------------------------- #

RGB_REGEX = r"\(\s*([\d\.]{1,3})\s*,\s*([\d\.]{1,3})\s*,\s*([\d\.]{1,3})\s*\)"
HEX_REGEX = r"#(?:[0-9a-fA-F]{3}){1,2}$"

"""
    is_named_color(string::String)::Bool

Check if a string represents a named color.
"""
is_named_color(string)::Bool = string ∈ NAMED_COLORS || string ∈ COLORS_16b


"""
    is_rgb_color(string::String)::Bool

Check if a string represents a RGB color.
"""
is_rgb_color(string)::Bool = !occursin("on_", string) && occursin(RGB_REGEX, string)

"""
    is_hex_color(string::String)::Bool

Check if a string represents a hex color.
"""
is_hex_color(string)::Bool = !occursin("on_", string) && occursin(HEX_REGEX, string)

"""
    is_color(string::String)::Bool

Check if a string represents color information, of any type.
"""
is_color(string)::Bool = is_named_color(string) || is_rgb_color(string) || is_hex_color(string)


"""
    is_background(string::String)::Bool

Check if a string represents background color information, of any type.
"""
function is_background(string)::Bool
    stripped = nospaces(string)
    length(stripped) < 3 && return false
    return stripped[1:3] == "on_" && is_color(stripped[4:end])
end

# --------------------------------- get color -------------------------------- #
"""
    hex2rgb(hex::String)

Converts a string hex color code to a RGB color
"""
function hex2rgb(hex)::RGBColor
    to_int(h) = parse(Int, h; base = 16)
    r, g, b = [to_int(hex[i:(i + 1)]) for i in (2, 4, 6)]
    return RGBColor(r, g, b)
end

"""
    get_color(string::String; bg=false)::AbstractColor

Extract a color type from a string with color information.
"""
function get_color(string; bg = false)::AbstractColor
    if bg
        string = nospaces(string)[4:end]
    end

    if is_named_color(string)
        if string ∈ COLORS_16b
            idx = findfirst((c) -> c == string, COLORS_16b)[1]
            return BitColor(COLORS_16b[idx])
        else
            idx = findfirst((c) -> c == string, NAMED_COLORS)[1]
            return NamedColor(NAMED_COLORS[idx])
        end
    elseif is_rgb_color(string)
        return RGBColor(string)
    else
        # convert hex to rgb
        return hex2rgb(string)
    end
end

end
