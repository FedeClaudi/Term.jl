module color
    include("__text_utils.jl")
    include("_ansi.jl")

    export NamedColor, BitColor, RGBColor, get_color

    # ----------------------------- types definition ----------------------------- #
    abstract type AbstractColor end

    Base.show(io::IO, color::AbstractColor) = print(io, "$(typeof(color))('$(color.color)')")

    struct NamedColor <: AbstractColor
        color::String
    end

    struct BitColor <: AbstractColor
        color::String
    end

    struct RGBColor <: AbstractColor
        color::String
        r::Int
        g::Int
        b::Int
    end
    function RGBColor(s::AbstractString)         
        r, g, b = _rgb(s)
        if r < 1
            r = (Int64 ∘ round)(r * 255)
            g = (Int64 ∘ round)(g * 255)
            b = (Int64 ∘ round)(b * 255)
        end
        return RGBColor(s, r, g, b)
    end


    # --------------------------------- is color? -------------------------------- #
    """
        _rgb(numbertype, txt)

    Tries to parse r,g,b out of a string based on number type
    """
    _rgb(number_type, txt) = begin
        rgb = split(remove_brackets(nospaces(txt)), ",")
        r = parse(number_type, rgb[1])
        g = parse(number_type, rgb[2])
        b = parse(number_type, rgb[3])
        return r, g, b
    end

    """
        _rgb(numbertype, txt)

    Tries to parse r,g,b out of a string
    """
    function _rgb(txt)
        try
            r,g,b =  _rgb(Float64, txt)

        catch
            return _rgb(Int64, txt)
        end
    end

    function is_named_color(string::AbstractString)::Bool
        if string ∈ NAMED_COLORS || string ∈ COLORS_16b
            return true
        else
            return false
        end
    end
    
    function is_rgb_color(string::AbstractString)::Bool
        try
            _rgb(string)
            return true
        catch
            return false
        end
    end
    
    function is_hex_color(string::AbstractString)::Bool
        stripped = nospaces(string)
        l = length(stripped)
        if stripped[1] == '#' && l==7
            return true
        else
            return false
        end
    end
    
    
    function is_color(string::AbstractString)::Bool

        is_named = is_named_color(string)
        is_rgb = is_rgb_color(string)
        is_hex = is_hex_color(string)
        
        return is_named || is_rgb || is_hex
    end
    
    function is_background(string::AbstractString)::Bool
        stripped = nospaces(string)
        return stripped[1:3] == "on_" && is_color(stripped[4:end])
    end



    # --------------------------------- get color -------------------------------- #
    """
        hex2rgb(hex::AbstractString)

    Converts a string hex color code to a RGB color
    """
    function hex2rgb(hex::AbstractString)::RGBColor
        to_int(h::AbstractString) = parse(Int, h, base=16)
        r, g, b = [to_int(hex[i:i+1]) for i in (2, 4, 6)]
        return RGBColor("($r, $g, $b)", r, g, b)
    end
    
    
    function get_color(string::AbstractString; bg=false)::AbstractColor
        if bg
            string = nospaces(string)[4:end]
        end

        if is_named_color(string)
            if string ∈ COLORS_16b
                idx = findfirst((c) -> c==string, COLORS_16b)[1]
                return BitColor(COLORS_16b[idx])
            else
                idx = findfirst((c) -> c==string, NAMED_COLORS)[1]
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