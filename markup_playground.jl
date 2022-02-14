


println("\n")


tests = [
    "[red]color[/red]white",
    "[red on_green]color[/red on_green]white",
    "[blue bold on_red] test // [/blue bold on_red]",
    "[bold] [ test [/bold]",
    "[bold] ] test [/bold]",
    "[bold on_white] [] test [/bold on_white]",
    "[bold italic] / test [/bold italic]",
    "[red] outer [blue] inner [/blue] and close [/red]",
    "[ red  on_blue] test with spaces [/ red  on_blue]",
]
test = "[red]color[/red]white"

open_regex=r"\[[a-zA-Z _]+[^/]\]"

tag_close_regex=r"\[\/+[a-zA-Z _]*\]"




# ---------------------------------------------------------------------------- #
#                                     color                                    #
# ---------------------------------------------------------------------------- #
abstract type AbstractColor end
Base.show(io::IO, color::AbstractColor) = print(color.color)

struct NamedColor <: AbstractColor
    color::String
end

struct BitColor <: AbstractColor
    color::String
end

struct RGBColor <: AbstractColor
    color::String
end

function string2rgb(string::AbstractString)::RGBColor
    stripped = nospaces(string)
    l = length(stripped)

    if l == 7  # float rgb passed
        try
            r = parse(Float64, rgb[1])
            g = parse(Float64, rgb[2])
            b = parse(Float64, rgb[3])
        finally
            return RGB("($(Int(round(r*255))), $(Int(round(g*255))), $(Int(round(b*255))))")
        end
        
    else
        try
            r = parse(Int64, rgb[1])
            g = parse(Int64, rgb[2])
            b = parse(Int64, rgb[3])
        finally
            return RGB("($r, $g, $b)")
        end
        
    end
end


function hex2rgb(string::AbstractString)::RGBColor
    throw("not implemented")
    r, g, b = "to", "do", "one day"
    return RGB("($r, $g, $b)")
end

function is_named_color(string::AbstractString)::Bool
    if string ∈ NAMED_COLORS || string ∈ COLORS_16b
        return true
    else
        return false
    end
end

function is_rgb_color(string::AbstractString)::Bool
    stripped = nospaces(string)
    l = length(stripped)
    if l == 7 || l == 13
        rgb = split(remove_brackets(stripped))
        if length(rgb) == 3
            if l == 7  # float rgb passed
                try
                    r = parse(Float64, rgb[1])
                    g = parse(Float64, rgb[2])
                    b = parse(Float64, rgb[3])
                finally
                    return true
                end
                
            else
                try
                    r = parse(Int64, rgb[1])
                    g = parse(Int64, rgb[2])
                    b = parse(Int64, rgb[3])
                finally
                    return true
                end
                
            end
        end
    end
    return false
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



function get_color(string::AbstractString)::AbstractColor
    if is_named_color(string)
        if string ∈ COLORS_16b
            idx = findfirst((c) -> c==string, COLORS_16b)[1]
            return NamedColor(COLORS_16b[idx])
        else
            idx = findfirst((c) -> c==string, NAMED_COLORS)[1]
            return NamedColor(NAMED_COLORS[idx])
        end
    elseif is_rgb_color(string)
        return string2rgb(string)
    else
        return hex2rgb(string)
    end
end

# ---------------------------------------------------------------------------- #
#                                     style                                    #
# ---------------------------------------------------------------------------- #

is_mode(string::AbstractString) = string ∈ NAMED_MODES

import Parameters: @with_kw

@with_kw mutable struct MarkupStyle
    normal::Bool        = false
    bold::Bool          = false
    dim::Bool           = false
    italic::Bool        = false
    underline::Bool     = false
    blinking::Bool      = false
    inverse::Bool       = false
    hidden::Bool        = false
    striked::Bool       = false

    color::AbstractColor       = NamedColor("default")
    background::AbstractColor       = NamedColor("default")

    tag::MarkupTag
end

function MarkupStyle(tag::MarkupTag)
    codes = split(tag.markup)

    style = MarkupStyle(tag=tag)
    # setproperty!(style, color) = NamedColor("red")
    setproperty!(style, :normal, true)

    for code in codes
        if is_mode(code)
            setproperty!(style, Symbol(code), true)
        elseif is_color(code)
            setproperty!(style, :color, get_color(code))
        elseif is_background(code)
            setproperty!(style, :background, get_color(code[4:end]))
        else
            @warn "Code type not recognized: $code"
        end
    end
    return style
end



for test in tests
    println("\e[1;32m"*test*"\e[9;39m")
    tags = []
    while occursin(open_regex, test)
        # get tag declaration
        tag_open = SingleTag(match(open_regex, test))
        println(tag_open)

        # get tag closing
        close_regex = r"\[\/+" * tag_open.markup * r"\]"
        if !occursin(close_regex, test[tag_open.stop:end])
            @warn "Could not find closing tag for $tag_open in $test"
            continue
        end

        tag_close = SingleTag(match(close_regex, test, tag_open.start))
        println(tag_close)

        # get tag
        markup_tag = MarkupTag(tag_open, tag_close)

        # create style from tag
        style = MarkupStyle(markup_tag)
        @info "Style" style

        println(style.color)
        println(style.background)

        # push!(tags, Tag(tag_open, tag_close))
        break
    end

    # has_match = occursin(open_regex, test)
    # if has_match
    #     println(match(open_regex, test))
    # else
    #     println("!!!! TAG OPEN no match for '$test'")
    # end

    # has_match = occursin(tag_close_regex, test)
    # if has_match
    #     println(match(tag_close_regex, test))
    # else
    #     println("!!!! TAG CLOSE no match for '$test'")
    # end
    print("\n")
end
