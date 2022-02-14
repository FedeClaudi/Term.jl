module measure
    include("utils.jl")

    import ..renderable: AbstractRenderable, LINE
    import ..text: apply_style

    export Measure

    # ---------------------------------------------------------------------------- #
    #                                    MEASURE                                   #
    # ---------------------------------------------------------------------------- #
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
        return Measure(renderable.string)
    end

    """
        Measure(string)
    """
    function Measure(text::AbstractString) 
        lines = split_lines(text; discard_empty=false)
        if length(lines) == 0
            return Measure(0, 1)
        end

        Measure(
            max([length(strip_ansi(apply_style(l))) for l in lines]...),
            length(lines)
        )
    end

    Merasure(line::LINE) = Measure(0, 1)



    # ---------------------------------------------------------------------------- #
    #                                     utils                                    #
    # ---------------------------------------------------------------------------- #

    # ------------------------------- string utils ------------------------------- #
    """
    Gets the 'width' of each character.

    a = "test"
    length(a) == sum(lengths(a))

    b = "╭───────────╮"
    lenth(b) < sum(lengths(b))
    """
    lengths(str::String) = [ncodeunits(c) for c in str]

    count_codeunits(str::AbstractString) = sum(lengths(str))

    n_valid_indices(str::String) = length([i for i in 1:ncodeunits(str) if isvalid(str, i)])
end