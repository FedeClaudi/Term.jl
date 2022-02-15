module box
    include("__text_utils.jl")
    
    export ASCII, ASCII2, ASCII_DOUBLE_HEAD, SQUARE, SQUARE_DOUBLE_HEAD, MINIMAL, MINIMAL_HEAVY_HEAD
    export MINIMAL_DOUBLE_HEAD, SIMPLE, SIMPLE_HEAD, SIMPLE_HEAVY, HORIZONTALS, ROUNDED, HEAVY
    export HEAVY_EDGE, HEAVY_HEAD, DOUBLE, DOUBLE_EDGE
    export ALL_BOXES

    # ---------------------------------------------------------------------------- #
    #                                      BOX                                     #
    # ---------------------------------------------------------------------------- #
    """
    Defines the characters in a single line of a `Box`
    """
    struct BoxLine
        left::Char
        mid::Char
        vertical::Char
        right::Char
    end

    """
    Defines characters to render boxes.

    ┌─┬┐ top
    │ ││ head
    ├─┼┤ head_row
    │ ││ mid
    ├─┼┤ row
    ├─┼┤ foot_row
    │ ││ foot
    └─┴┘ bottom
    """
    struct Box
        name::String
        top::BoxLine
        head::BoxLine
        head_row::BoxLine
        mid::BoxLine
        row::BoxLine
        foot_row::BoxLine
        foot::BoxLine
        bottom::BoxLine
    end

    """
        Box(string)

    Constructs a `Box` objet out of a box string.
    """
    function Box(box_name, box::String)
        top, head, head_row, mid, row, foot_row, foot, bottom = split(box, "\n")

        Box(
            box_name,
            BoxLine(chars(top)...),
            BoxLine(chars(head)...),
            BoxLine(chars(head_row)...),
            BoxLine(chars(mid)...),
            BoxLine(chars(row)...),
            BoxLine(chars(foot_row)...),
            BoxLine(chars(foot)...),
            BoxLine(chars(bottom)...),
        )
    end


    function Base.show(io::IO, box::Box)
        print(io, "Box ($(box.name))\n$(fit(box, [1, 3, 1]))")
    end

    """
        get_row(box, [1, 2, 3], :row)

    Gets characters for a row of a Box object.
    The level Symbold can be used to specify the box level (:top, :footer...)
    """
    function get_row(box::Box, widths::Vector{Int}, level::Symbol)::String
        # get the correct level of the box
        level = getfield(box, level)
    
        parts = [string(level.left)]
        for (last, w) in loop_last(widths)
            segment = last ? level.mid^w * level.right : level.mid^w * level.vertical
            push!(parts, segment)
        end
        join(parts)
    end
    
    """
    Creates a box with one of each level type with columns
    widths specified by a vector of widhts.
    """
    function fit(box::Box, widths::Vector{Int})::String
        strings = [
            get_row(box, widths, :top),
            get_row(box, widths, :head),
            get_row(box, widths, :head_row),
            get_row(box, widths, :mid),
            get_row(box, widths, :row),
            get_row(box, widths, :foot_row),
            get_row(box, widths, :foot),
            get_row(box, widths, :bottom),
        ]
        return merge_lines(strings)
    end


    # ---------------------------------------------------------------------------- #
    #                                   Box types                                  #
    # ---------------------------------------------------------------------------- #


    ASCII = Box(
    "ASCII",
    """
    +--+
    | ||
    |-+|
    | ||
    |-+|
    |-+|
    | ||
    +--+
    """
    )
    
    ASCII2 = Box(
    "ASCII2",
    """
    +-++
    | ||
    +-++
    | ||
    +-++
    +-++
    | ||
    +-++
    """
    )
    
    ASCII_DOUBLE_HEAD = Box(
    "ASCII_DOUBLE_HEAD",
    """
    +-++
    | ||
    +=++
    | ||
    +-++
    +-++
    | ||
    +-++
    """
    )
    
    SQUARE = Box(
    "SQUARE",
    """
    ┌─┬┐
    │ ││
    ├─┼┤
    │ ││
    ├─┼┤
    ├─┼┤
    │ ││
    └─┴┘
    """
    )
    
    SQUARE_DOUBLE_HEAD = Box(
    "SQUARE_DOUBLE_HEAD",
    """
    ┌─┬┐
    │ ││
    ╞═╪╡
    │ ││
    ├─┼┤
    ├─┼┤
    │ ││
    └─┴┘
    """
    )
    
    MINIMAL = Box(
    "MINIMAL",
    """
      ╷ 
      │ 
    ╶─┼╴
      │ 
    ╶─┼╴
    ╶─┼╴
      │ 
      ╵ 
    """
    )
    
    
    MINIMAL_HEAVY_HEAD = Box(
    "MINIMAL_HEAVY_HEAD",
    """
      ╷ 
      │ 
    ╺━┿╸
      │ 
    ╶─┼╴
    ╶─┼╴
      │ 
      ╵ 
    """
    )
    
    MINIMAL_DOUBLE_HEAD = Box(
    "MINIMAL_DOUBLE_HEAD",
    """
      ╷ 
      │ 
     ═╪ 
      │ 
     ─┼ 
     ─┼ 
      │ 
      ╵ 
    """
    )
    
    
    SIMPLE = Box(
    "SIMPLE",
    """
        
        
     ── 
        
        
     ── 
        
        
    """
    )
    
    SIMPLE_HEAD = Box(
    "SIMPLE_HEAD",
    """
        
        
     ── 
        
        
        
        
        
    """
    )
    
    
    SIMPLE_HEAVY = Box(
    "SIMPLE_HEAVY",
    """
        
        
     ━━ 
        
        
     ━━ 
        
        
    """
    )
    
    
    HORIZONTALS = Box(
    "HORIZONTALS",
    """
     ── 
        
     ── 
        
     ── 
     ── 
        
     ── 
    """
    )
    
    ROUNDED = Box(
    "ROUNDED",
    """
    ╭─┬╮
    │ ││
    ├─┼┤
    │ ││
    ├─┼┤
    ├─┼┤
    │ ││
    ╰─┴╯
    """
    )
    
    HEAVY = Box(
    "HEAVY",
    """
    ┏━┳┓
    ┃ ┃┃
    ┣━╋┫
    ┃ ┃┃
    ┣━╋┫
    ┣━╋┫
    ┃ ┃┃
    ┗━┻┛
    """
    )
    
    HEAVY_EDGE = Box(
    "HEAVY_EDGE",
    """
    ┏━┯┓
    ┃ │┃
    ┠─┼┨
    ┃ │┃
    ┠─┼┨
    ┠─┼┨
    ┃ │┃
    ┗━┷┛
    """
    )
    
    HEAVY_HEAD = Box(
    "HEAVY_HEAD",
    """
    ┏━┳┓
    ┃ ┃┃
    ┡━╇┩
    │ ││
    ├─┼┤
    ├─┼┤
    │ ││
    └─┴┘
    """
    )
    
    DOUBLE = Box(
    "DOUBLE",
    """
    ╔═╦╗
    ║ ║║
    ╠═╬╣
    ║ ║║
    ╠═╬╣
    ╠═╬╣
    ║ ║║
    ╚═╩╝
    """
    )
    
    DOUBLE_EDGE = Box(
    "DOUBLE_EDGE",
    """
    ╔═╤╗
    ║ │║
    ╟─┼╢
    ║ │║
    ╟─┼╢
    ╟─┼╢
    ║ │║
    ╚═╧╝
    """
    )
end