module layout
    include("__text_utils.jl")


    import ..renderables: RenderablesUnion, Renderable, AbstractRenderable
    import ..measure: Measure
    import ..segment: Segment
    using ..box
    import Term: int
    import ..consoles: console_width, console_height

    export Padding, vstack, hstack
    export Spacer, vLine, hLine


    # ---------------------------------------------------------------------------- #
    #                                    PADDING                                   #
    # ---------------------------------------------------------------------------- #
    """
    Stores string to pad a string to a given width
    """
    struct Padding
        left::AbstractString
        right::AbstractString
    end

    """Creates a Padding for a string to match a given width according to a justify method"""
    function Padding(text::AbstractString, target_width::Int, method::Symbol)::Padding
        # get total padding size
        lw = Measure(text).w
        if lw == target_width
            return Padding("", "")
        else
            if lw < target_width 
                @debug "\e[31mTarget width is $target_width but the text has width $lw: \e[0m\n   $text\n     Cleaned: '$(remove_ansi(remove_markup(text)))'"
            end
        end
        padding = " "^(target_width - lw -1)
        pad_width = Measure(padding).w

        # split left/right padding for left/right justify
        if pad_width > 0
            cut = pad_width%2 == 0 ? Int(pad_width/2) : (Int ∘ floor)(pad_width/2)
            left, right = padding[1:cut], padding[cut+1:end]
            @assert length(left * right) <= length(padding) "\e[31m$(length(left * right)) instead of $(length(padding))"
        else
            left, right = "", ""
        end

        # craete padding
        if method == :center
            padding = Padding(" "*left, right)
        elseif method == :left
            padding = Padding(" ", padding)
        elseif method == :right
            padding = Padding(padding, " ")
        end

        # @info "made padding" text target_width method padding lw pad_width left right
        @assert Measure(padding.left * text * padding.right).w <= target_width "\e[31mPadded width $(Measure(padding.left * text * padding.right).w), target: $target_width $padding"
        
        return padding
    end

    function Base.show(io::IO, padding::Padding)
        print(io, "$(typeof(padding))  \e[2m(left: $(length(padding.left)), right: $(length(padding.right)))\e[0m")
    end    

  

    # ---------------------------------------------------------------------------- #
    #                                   STACKING                                   #
    # ---------------------------------------------------------------------------- #
    """
        vstack(r1::RenderablesUnion, r2::RenderablesUnion)

    Vertically stacks two renderables to give a new renderable.
    """
    function vstack(r1::RenderablesUnion, r2::RenderablesUnion)
        r1 = Renderable(r1)
        r2 = Renderable(r2)

        # get dimensions of final renderable
        w1 = r1.measure.w
        w2 = r2.measure.w

        # create segments stack
        segments::Vector{Segment} = vcat(r1.segments, r2.segments)
        measure = Measure(max(w1, w2), length(segments))

        return Renderable(
            segments,
            measure,
        )
    end

    """ 
        vstack(renderables...)

    Vertically stacks a variable number of renderables
    """
    function vstack(renderables...)
        renderable = Renderable()

        for ren in renderables
            renderable = vstack(renderable, ren)
        end
        return renderable
    end


    """
        hstack(r1::RenderablesUnion, r2::RenderablesUnion)

    Horizontally stacks two renderables to give a new renderable.
    """
    function hstack(r1::RenderablesUnion, r2::RenderablesUnion)
        r1 = Renderable(r1)
        r2 = Renderable(r2)

        # get dimensions of final renderable
        h1 = r1.measure.h
        h2 = r2.measure.h

        # make sure both renderables have the same number of segments
        Δh = abs(h2-h1)
        if h1 > h2
            r2.segments = vcat(r2.segments, [Segment(" "^r2.measure.w) for i in 1:Δh])
        elseif h1 < h2
            r1.segments = vcat(r1.segments, [Segment(" "^r1.measure.w) for i in 1:Δh])
        end

        # combine segments
        segments = [Segment(s1.text * s2.text) for (s1, s2) in zip(r1.segments, r2.segments)]

        return Renderable(
            segments,
            Measure(segments),
        )
    end

    """ 
        hstack(renderables...)

    Horizonatlly stacks a variable number of renderables
    """
    function hstack(renderables...)
        renderable = Renderable()

        for ren in renderables
            renderable = hstack(renderable, ren)
        end
        return renderable
    end


    # --------------------------------- operators -------------------------------- #

    """
        Operators for more coincise layout of renderables
    """

    Base.:/(r1::RenderablesUnion, r2::RenderablesUnion) = vstack(r1, r2)

    Base.:*(r1::AbstractRenderable, r2::AbstractRenderable) = hstack(r1, r2)
    Base.:*(r1::AbstractString,     r2::AbstractRenderable) = hstack(r1, r2)
    Base.:*(r1::AbstractRenderable, r2::AbstractString)     = hstack(r1, r2)

    # ---------------------------------------------------------------------------- #
    #                                LINES & SPACER                                #
    # ---------------------------------------------------------------------------- #
    abstract type AbstractLayoutElement <: AbstractRenderable end
    mutable struct Spacer <: AbstractLayoutElement
        segments::Vector{Segment}
        measure::Measure
    end

    function Spacer(width::Number, height::Number; char::Char=' ')
        width = int(width)
        height = int(height)

        line = char^width
        segments = [Segment(line) for i in 1:height]
        return Spacer(segments, Measure(segments))
    end

    """
        vLine
    
    A multi-line renderable with each line made of a | 
    to create a vertical line
    """
    mutable struct vLine <: AbstractLayoutElement
        segments::Vector{Segment}
        measure::Measure
        height::Int
    end

    """
        vLine(height::Number, style::Union{String, Nothing}; box::Symbol=:ROUNDED)

    Constructor to create a styled vertical line of viven height.

    """
    function vLine(height::Number; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)
        height = int(height)
        char = string(eval(box).head.left)
        segments = [Segment(char, style) for i in 1:height]
        return vLine(segments, Measure(segments), height)
    end

    vLine(; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED) = vLine(console_height(); style=style, box=box)

    """
        hLine

    A 1-line renderable made of repeated character from a Box.
    """
    mutable struct hLine <: AbstractLayoutElement
        segments::Vector{Segment}
        measure::Measure
        width::Int
    end

    """
        hLine(width::Number, style::Union{String, Nothing}; box::Symbol=:ROUNDED)
    
    constructor to create a styled hLine of given width
    """
    function hLine(width::Number; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)
        width = int(width)
        char = eval(box).row.mid
        segments = [Segment(char^width, style)]
        return hLine(segments, Measure(segments), width)
    end

    """
        hLine(width::Number, text::String; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)

    Creates an hLine object with texte centered horizontally
    """
    function hLine(width::Number, text::String; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED)
        box = eval(box)

        initial_line = box.top.mid^width

        cutval = int(ncodeunits(initial_line)/2 - ncodeunits(text) - 5)
        cut_start = get_last_valid_str_idx(initial_line, cutval)

        pre = Segment(
          Segment(initial_line[1:cut_start], style) * "\e[0m" * " " * Segment(text, style) * " "
        )            

        post =  Segment(box.top.mid^(length(initial_line) - pre.measure.w - 1), style)

        segments = [Segment(pre * (post), style)]
        return hLine(segments, Measure(segments), width)
    end
    
    hLine(; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED) = hLine(console_width(); style=style, box=box)
    hLine(text::AbstractString; style::Union{String, Nothing}=nothing, box::Symbol=:ROUNDED) = hLine(console_width(), text; style=style, box=box)
end