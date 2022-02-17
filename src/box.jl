module box
    include("__text_utils.jl")

    import ..segment: Segment
    import ..style: apply_style

    export get_row, get_title_row
    export ASCII, ASCII2, ASCII_DOUBLE_HEAD, SQUARE, SQUARE_DOUBLE_HEAD, MINIMAL, MINIMAL_HEAVY_HEAD
    export MINIMAL_DOUBLE_HEAD, SIMPLE, SIMPLE_HEAD, SIMPLE_HEAVY, HORIZONTALS, ROUNDED, HEAVY
    export HEAVY_EDGE, HEAVY_HEAD, DOUBLE, DOUBLE_EDGE

    """
    Returns an iterable yielding tuples (is_last, value)
    where is_last == true only if value is the lest item in v.
    """
    function loop_last(v::Vector)
        is_last = [i==length(v) for i in 1:length(v)]
        return zip(is_last, v)
    end

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
      if io == stdout 
          print(io, "Box ($(box.name))\n$(fit(box, [1, 3, 1]))")
      elseif io == stderr
          print(io, "err")
      else    
          print(io, "Box\e[2m($(box.name))\e[0m")
      end
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
    
    function get_title_row(
        row::Symbol,
        box::Box,
        title::Union{Nothing, AbstractString}; 
        width::Int,
        style::Union{Nothing, String},
        title_style::Union{Nothing, AbstractString},
        justify::Symbol=:left,
      )

      initial_line = Segment(get_row(box, [width], row), style).plain

      if isnothing(title)
        return Segment(initial_line, style)
      else

        # get title
        title=Segment(title)
        @assert title.measure.w < width - 4 "Title too long for panel of width $width"
        
        # compose title line 
        line = getfield(box, row)

        # initial_line = initial_line.text
        if justify == :left
          cut_start = get_last_valid_str_idx(initial_line, 4)
          pre = Segment(
            Segment(initial_line[1:cut_start], style) * "\e[0m" * " " * Segment(title, title_style).text * " "
          )            
          post = line.mid^(length(initial_line) - pre.measure.w - 1) * line.right
        else
          cut_start = get_next_valid_str_idx(initial_line, ncodeunits(initial_line)-8)
          post = Segment(
            "\e[0m" * " " * Segment(title, title_style).text * " " * Segment(initial_line[cut_start:end], style)
          )          

          pre = Segment(line.left * line.mid^(length(initial_line) - post.measure.w - 1), style)
        end
        return pre * Segment(post, style)
        # return Segment(post, style)
      end
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