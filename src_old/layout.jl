module layout
    import ..renderable: AbstractRenderable
    import ..measure: Measure
    import ..box: ALL_BOXES
    import ..text: apply_style

    export Padding, Separator


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
        lw = Measure(text).width
        @assert lw < target_width "Text is longer than the target width"

        # get total padding size
        padding = lw < target_width ? " "^(target_width - lw -1) : ""
        lPad = Measure(padding).width
        
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
    #                                LINE SEPARATOR                                #
    # ---------------------------------------------------------------------------- #
    struct Separator <: AbstractRenderable
        string::AbstractString
    end

    function Separator(n::Int; box::Symbol=:ROUNDED, style::Union{AbstractString, Nothing}=nothing)
        box = ALL_BOXES[box]
        return Separator(apply_style(box.row.mid^n, style))
    end

    function Separator(renderable::AbstractRenderable; box::Symbol=:ROUNDED, style::Union{AbstractString, Nothing}=nothing)
        measure = Measure(renderable)
        return Separator(measure.width; box=box)
    end

end