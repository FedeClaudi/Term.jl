module layout
    import ..renderables: RenderablesUnion, Renderable
    import ..measure: Measure
    import ..segment: Segment

    export Padding, vstack


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
        w1, h1 = r1.measure.w, r1.measure.h
        w2, h2 = r2.measure.w, r2.measure.h

        width = max(w1, w2)
        height = h1 + h2

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

    vstack(r1::RenderablesUnion) = r1

end