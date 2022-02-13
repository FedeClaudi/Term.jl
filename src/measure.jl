module measure
    import ..renderable: AbstractRenderable

    export Measure

    """
    Holds information about the width and height of an AbstractRenderable
    """
    struct Measure
        width::Int
        height::Int
    end

    """
        Measure(renderable)

    Given an abstract renderable with a `.string` field, it returns
    a `Measure` with width=length of longest line in renderable.string 
    and height = number of lines in renderable.string.
    """
    function Measure(renderable::AbstractRenderable) 
        lines = spli(renderable.string)
        Measure(
            max([length(l) for l in lines]...),
            length(lines)
        )
    end
end