


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
