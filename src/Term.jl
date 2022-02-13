module Term
    include("all_modules.jl")

    using .box: Box, fit, ALL_BOXES

    using .markup: Tag

    using .measure: Measure

    using .renderable: AbstractRenderable, AbstractText, AbstractPanel, Line, Empty, Space
    using .renderable: LINE

    using .text: MarkupText, apply_style, plain

    using .layout: Padding, Separator

    using .panel: Panel


    export MarkupText, Measure
    export Panel
    export Line, Space, Empty
    export Separator
    export tprint, info

    # -------------------------------- typed utils ------------------------------- #
    lines(l::LINE; discard_empty=true) = ["\n"]
    split_lines(l::LINE; discard_empty=true) = ["\n"]

    # ---------------------------------------------------------------------------- #
    #                                    tprint                                    #
    # ---------------------------------------------------------------------------- #
    """ 
        tprint(text::String)

    Stylized printing of a string as MarkupText
    """
    tprint(text::String) = tprint(MarkupText(text))

    """ 
        tprint(text::AbstractRenderable)

    Prints the string field of an AbstractRenderable
    """
    tprint(text::AbstractRenderable) = println(text.string)

    tprint(args...) = tprint.(args)

end

