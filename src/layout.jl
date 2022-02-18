module layout
    import ..renderables: RenderablesUnion, Renderable, AbstractRenderable
    import ..measure: Measure
    import ..segment: Segment
    using ..box

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
    function Padding(text, target_width, method)
        lw = Measure(text).w
        @assert lw < target_width "Text is longer than the target width: $lw instead of $target_width"

        # get total padding size
        padding = lw < target_width ? " "^(target_width - lw -1) : ""
        lPad = Measure(padding).w

        # split left/right padding for left/right justify
        if lPad > 0
            cut = lPad%2 == 0 ? Int(lPad/2) : (Int ∘ floor)(lPad/2)
            left, right = padding[1:cut], padding[cut+1:end]
        else
            left, right = "", ""
        end

        # craete padding
        if method == :center
            return Padding(" "*left, right)
        elseif method == :left
            return Padding(" ", padding)
        elseif method == :right
            return Padding(padding, " ")
        end
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

        # pad segments
        Δw = abs(w2-w1)
        if w1 > w2
            r2.segments = [Segment(s.text * " "^Δw) for s in r2.segments]
        elseif w1 < w2
            r1.segments = [Segment(s.text * " "^Δw) for s in r1.segments]
        end

        # create segments stack
        segments::Vector{Segment} = vcat(r1.segments, r2.segments)

        return Renderable(
            segments,
            Measure(segments),
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



    # ---------------------------------------------------------------------------- #
    #                                LINES & SPACER                                #
    # ---------------------------------------------------------------------------- #
    abstract type AbstractLayoutElement <: AbstractRenderable end
    mutable struct Spacer <: AbstractLayoutElement
        segments::Vector{Segment}
        measure::Measure
    end

    function Spacer(width::Number, height::Number; char::Char=' ')
        width = (Int ∘ round)(width)
        height = (Int ∘ round)(height)

        line = char^width
        segments = [Segment(line) for i in 1:height]
        return Spacer(segments, Measure(segments))
    end



    mutable struct vLine <: AbstractLayoutElement
        segments::Vector{Segment}
        measure::Measure
        height::Int
    end

    function vLine(height::Number, style::Union{String, Nothing}; box::Symbol=:ROUNDED)
        height = (Int ∘ round)(height)
        char = string(eval(box).head.left)
        segments = [Segment(char, style) for i in 1:height]
        return vLine(segments, Measure(segments), height)
    end


    mutable struct hLine <: AbstractLayoutElement
        segments::Vector{Segment}
        measure::Measure
        width::Int
    end

    function hLine(width::Number, style::Union{String, Nothing}; box::Symbol=:ROUNDED)
        width = (Int ∘ round)(width)
        segments = [Segment(eval(box).row.mid^width, style)]
        return hLine(segments, Measure(segments), width)
    end
end