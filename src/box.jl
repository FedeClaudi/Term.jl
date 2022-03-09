module box

import ..segment: Segment
import ..style: apply_style
import Term: int, chars, remove_markup_open, get_last_valid_str_idx, get_next_valid_str_idx

export get_row, get_title_row
export ASCII,
    ASCII2, ASCII_DOUBLE_HEAD, SQUARE, SQUARE_DOUBLE_HEAD, MINIMAL, MINIMAL_HEAVY_HEAD
export MINIMAL_DOUBLE_HEAD, SIMPLE, SIMPLE_HEAD, SIMPLE_HEAVY, HORIZONTALS, ROUNDED, HEAVY
export HEAVY_EDGE, HEAVY_HEAD, DOUBLE, DOUBLE_EDGE

"""
  loop_last(v::Vector)

  Returns an iterable yielding tuples (is_last, value).
"""
function loop_last(v::Vector)
    is_last = [i == length(v) for i in 1:length(v)]
    return zip(is_last, v)
end

# ---------------------------------------------------------------------------- #
#                                      BOX                                     #
# ---------------------------------------------------------------------------- #
"""
  BoxLine

Stores the characters for a line of a `Box` object.
"""
struct BoxLine
    left::Char
    mid::Char
    vertical::Char
    right::Char
end

"""
  Box

Defines characters to render boxes.

Row names:

┌─┬┐ top
│ ││ head
├─┼┤ head_row
│ ││ mid
├─┼┤ row
├─┼┤ foot_row
│ ││ foot
└─┴┘ bottom

each row is an instance of `BoxLine`
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

Construct a `Box` objet out of a box string.
"""
function Box(box_name::String, box::String)
    top, head, head_row, mid, row, foot_row, foot, bottom = split(box, "\n")

    return Box(
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

The level Symbol can be used to specify the box level (:top, :footer...)
"""
function get_row(box::Box, widths::Vector{Int}, level::Symbol)::String
    # get the correct level of the box
    level = getfield(box, level)

    parts = [string(level.left)]
    for (last, w) in loop_last(widths)
        segment = last ? level.mid^w * level.right : level.mid^w * level.vertical
        push!(parts, segment)
    end
    return join(parts)
end

"""
  get_title_row(row::Symbol, box::Box, title::Union{Nothing, AbstractString}; <keyword arguments>)

Create a box row with a title string.

Can create both titles in the top and bottom row to produce subtitles.

#Arguments:
- width::Int: width of line
- style::Union{Nothing:  String}: style of line
- title_style::Union{Nothing:  AbstractString}: style of title string
- justify::Symbol=:left: position of title string

See also [`get_row`](@ref).


"""
function get_title_row(
    row::Symbol,
    box::Box,
    title::Union{Nothing,AbstractString};
    width::Int,
    style::Union{Nothing,String},
    title_style::Union{Nothing,AbstractString},
    justify::Symbol = :left,
)
    initial_line = remove_markup_open(Segment(get_row(box, [width], row), style).plain)
    # @info "Getting title row" initial_line

    if isnothing(title)
        return Segment(initial_line, style)
    else

        # get title
        title = apply_style("[$title_style]" * title)
        @assert Segment(title).measure.w < width - 4 "Title too long for panel of width $width: $title, ($(Segment(title).measure.w))"

        # compose title line 
        line = getfield(box, row)

        if justify == :left
            cut_start = get_last_valid_str_idx(initial_line, 4)
            pre = Segment(
                Segment(initial_line[1:cut_start], style) * "\e[0m" * " " * title * " "
            )

            post = line.mid^(length(initial_line) - pre.measure.w - 1) * line.right

        elseif justify == :right
            cut_start = get_next_valid_str_idx(initial_line, ncodeunits(initial_line) - 8)
            post = Segment(
                "\e[0m" * " " * title * " " * Segment(initial_line[cut_start:end], style)
            )

            pre = Segment(
                line.left * line.mid^(length(initial_line) - post.measure.w - 1), style
            )

        else  # justify :center
            cutval = int(ncodeunits(initial_line) / 2 - ncodeunits(title) / 2 - 15)

            cut_start = get_last_valid_str_idx(initial_line, cutval)
            # @info width cutval cut_start length(initial_line) length(initial_line) ncodeunits(initial_line)

            pre = Segment(
                Segment(initial_line[1:cut_start], style) * "\e[0m" * " " * title * " "
            )

            post = line.mid^(length(initial_line) - pre.measure.w - 1) * line.right
        end

        return pre * Segment(post, style)
        # return Segment(post, style)
    end
end

"""
  fit(box::Box, widths::Vector{Int})::String

Creates a box.

The box has one of each level type with columns
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
    return join_lines(strings)
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
    """,
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
    """,
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
    """,
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
    """,
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
    """,
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
    """,
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
    """,
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
    """,
)

SIMPLE = Box(
    "SIMPLE",
    """
        
        
     ── 
        
        
     ── 
        
        
    """,
)

SIMPLE_HEAD = Box(
    "SIMPLE_HEAD",
    """
        
        
     ── 
        
        
        
        
        
    """,
)

SIMPLE_HEAVY = Box(
    "SIMPLE_HEAVY",
    """
        
        
     ━━ 
        
        
     ━━ 
        
        
    """,
)

HORIZONTALS = Box(
    "HORIZONTALS",
    """
     ── 
        
     ── 
        
     ── 
     ── 
        
     ── 
    """,
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
    """,
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
    """,
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
    """,
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
    """,
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
    """,
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
    """,
)
end
