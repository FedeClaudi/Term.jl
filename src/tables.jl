module Tables

import Tables as TablesPkg

import Term: do_by_line, fillin, str_trunc, TERM_THEME

import ..Renderables: AbstractRenderable, RenderableText
import ..Layout: cvstack, hstack, vstack, pad, vLine, vertical_pad
import ..Measures: Measure, width, height
import ..Style: apply_style
import ..Segments: Segment
import ..Tprint: tprintln
using ..Boxes

export Table

theme = TERM_THEME[]
include("_tables.jl")

"""
    Table

A Table renderable.

# Examples
```julia

t = 1:3
data = hcat(t, rand(Int8, length(t)))
Table(data)

┌───────────┬───────────┐
│  Column1  │  Column2  │
├───────────┼───────────┤
│     1     │    -95    │
├───────────┼───────────┤
│     2     │    -85    │
├───────────┼───────────┤
│     3     │    115    │
└───────────┴───────────┘
```
"""
mutable struct Table <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
end

"""
    Table(
        tb::TablesPkg.AbstractColumns;
        box::Symbol = :SQUARE,
        style::String = "default",
        hpad::Union{Vector,Int} = 2,
        vpad::Union{Vector,Int} = 0,
        vertical_justify::Symbol = :center,
        show_header::Bool = true,
        header::Union{Nothing,Vector,Tuple} = nothing,
        header_style::Union{String,Vector,Tuple} = "default",
        header_justify::Union{Nothing,Symbol,Vector,Tuple} = nothing,
        columns_style::Union{String,Vector,Tuple} = "default",
        columns_justify::Union{Symbol,Vector,Tuple} = :center,
        columns_widths::Union{Nothing,Int,Vector} = nothing,
        footer::Union{Function,Nothing,Vector,Tuple} = nothing,
        footer_style::Union{String,Vector,Tuple} = "default",
        footer_justify::Union{Nothing,Symbol,Vector,Tuple} = :center,
        compact::Bool = false,
    )

Generic constructor for a Table renderable.

!!! tip
    Arguments such as `header_style`, `columns_style` and `footer_style` can 
    either be passed a single value, which will be applied to all columns, or
    a vector of values, which will be applied to each column.
"""
function Table(
    tb::TablesPkg.AbstractColumns;
    box::Symbol = TERM_THEME[].tb_box,
    style::String = TERM_THEME[].tb_style,
    hpad::Union{Vector,Int} = 2,
    vpad::Union{Vector,Int} = 0,
    vertical_justify::Symbol = :center,
    show_header::Bool = true,
    header::Union{Nothing,Vector,Tuple} = nothing,
    header_style::Union{String,Vector,Tuple} = TERM_THEME[].tb_header,
    header_justify::Union{Nothing,Symbol,Vector,Tuple} = nothing,
    columns_style::Union{String,Vector,Tuple} = TERM_THEME[].tb_columns,
    columns_justify::Union{Symbol,Vector,Tuple} = :center,
    columns_widths::Union{Nothing,Int,Vector} = nothing,
    footer::Union{Function,Nothing,Vector,Tuple} = nothing,
    footer_style::Union{String,Vector,Tuple} = TERM_THEME[].tb_footer,
    footer_justify::Union{Nothing,Symbol,Vector,Tuple} = :center,
    compact::Bool = false,
)

    # prepare some variables
    header_justify = something(header_justify, columns_justify)
    box = BOXES[box]

    # table info
    rows = TablesPkg.rows(tb)
    sch = TablesPkg.schema(rows)
    N_cols = length(sch.names)
    N_rows = length(rows) + 2

    # make sure arguemnts combination is valud
    assert_table_arguments(
        N_cols,
        N_rows,
        show_header,
        header,
        header_style,
        header_justify,
        columns_style,
        columns_justify,
        columns_widths,
        footer,
        footer_style,
        footer_justify,
        hpad,
        vpad,
    ) || return nothing

    # columns style
    columns_style, columns_justify, hpad =
        expand.([columns_style, columns_justify, hpad], N_cols)
    vpad = expand(vpad, N_rows)

    # headers and headers style
    if show_header
        header = isnothing(header) ? string.(sch.names) : header
        header_style, header_justify = expand.([header_style, header_justify], N_cols)
    end

    # get footer (if it's a function)
    if footer isa Function
        try
            footer_entries = footer.(map(c -> tb[c], sch.names))
            footer = string(footer) * ": " .* string.(footer_entries)
        catch
            @warn "Could not apply function $footer to table - types mismatch?"
            footer = fill("couldn't apply", N_cols)
        end
    end

    # get the max-width of each column
    widths = calc_columns_widths(
        N_cols,
        N_rows,
        columns_widths,
        show_header,
        header,
        tb,
        sch,
        footer,
        hpad,
    )

    # get the table values as vectors of strings
    rows_values = []
    for row in rows
        _row::Vector = []
        TablesPkg.eachcolumn(sch, row) do val, i, nm
            push!(_row, val isa AbstractRenderable ? val : string(val))
        end
        push!(rows_values, _row)
    end

    # get the height of each row
    heights = rows_heights(N_rows, show_header, header, rows_values, footer, vpad)
    # @info "sizes" widths heights  tb sch

    # ----------------------------- create table rows ---------------------------- #
    nrows = length(rows_values)
    lines::Vector{String} = []
    # @info "creating table" heights widths

    # create a row for the header
    show_header && push!(
        lines,
        table_row(
            make_row_cells(
                header,
                header_style,
                header_justify,
                widths,
                hpad,
                heights[1],
                vertical_justify,
            ),
            widths,
            box,
            :top,
            :head,
            :head_row,
            style,
            heights[1];
            # compact = true
        ),
    )

    # add one row at the time
    for (l, row) in enumerate(rows_values)
        # get the row's content
        I = l + 1
        row = make_row_cells(
            row,
            columns_style,
            columns_justify,
            widths,
            hpad,
            heights[I],
            vertical_justify,
        )

        # prep row params based on line number, header etc...
        if l == 1 && show_header
            bottom = if nrows < 2
                :bottom
            elseif nrows > 2
                :row
            else
                :foot_row
            end
            top = show_header ? nothing : :top
            mid = :mid
            _compact = (show_header && (box != BOXES[:NONE])) ? false : compact

            # add additional rows
        elseif l == nrows
            top, mid, bottom, _compact =
                nothing, :mid, isnothing(footer) ? :bottom : :foot_row, false
        else
            top, mid, bottom, _compact = nothing, :mid, :row, compact
        end

        # add it in
        push!(
            lines,
            table_row(
                row,
                widths,
                box,
                top,
                mid,
                bottom,
                style,
                heights[I];
                compact = _compact,
            ),
        )
    end

    # add footer
    if !isnothing(footer)
        # get footer style
        footer_justify = something(footer_justify, columns_justify)
        footer_style, footer_justify = expand.([footer_style, footer_justify], N_cols)

        push!(
            lines,
            table_row(
                make_row_cells(
                    footer,
                    footer_style,
                    footer_justify,
                    widths,
                    hpad,
                    heights[end],
                    vertical_justify,
                ),
                widths,
                box,
                nothing,
                :foot,
                :bottom,
                style,
                heights[end],
            ),
        )
    end

    lines = split(fillin(join(lines, "\n")), "\n")

    segments = Segment.(lines)
    return Table(segments, Measure(segments))
end

""" 
    Table(data::Union{AbstractVector, AbstractMatrix}; kwargs...)

Construct `Table` from `Vector` and `Matrix`
"""
Table(data::Union{AbstractVector,AbstractMatrix}; kwargs...) =
    Table(TablesPkg.table(data); kwargs...)

""" 
Table(data::AbstractDict; kwargs...)

Construct `Table` from a `Dict`.
The Dict's keys make up the table header if none is assigned.
"""
Table(data::AbstractDict; header = nothing, kwargs...) = Table(
    hcat(values(data)...);
    header = isnothing(header) ? string.(collect(keys(data))) : header,
    kwargs...,
)

"""
    function table_row(
        cells::Vector,
        widths::Vector,
        box::Symbol,
        top_level::Symbol,
        mid_level::Symbol,
        bottom_level::Symbol,
        box_style::String,
        row_height::Int;
        compact = false,
    )

Create a single row of a `Table` renderable. 

Each row is made up of an upper, mid and bottom section. The
upper and bottom sections are created by rows of the `Box` type.
The mid section is made up of the row's cells and dividing lines.

## Arguments
- cells: vector of cells content. Of length equal to the number of columns
- widths: vector of width of each cell.
- box: name of the `Box` used to construct the cell's lines
- top/mid/bottom_level: name of the `Box` level to be used for construction
- box_style: styling to be applied to box
- row_height: height of the row
- compact: if true avoids adding a top layer to the row
"""
function table_row(
    cells::Vector,
    widths::Vector,
    box,
    top_level::Union{Nothing,Symbol},
    mid_level::Symbol,
    bottom_level::Symbol,
    box_style,
    row_height::Int;
    compact::Bool = false,
)
    # get box characters
    mid_level = getfield(box, mid_level)

    l = vLine(row_height; style = box_style, char = mid_level.left)
    m = vLine(row_height; style = box_style, char = mid_level.vertical)
    r = vLine(row_height; style = box_style, char = mid_level.right)

    if row_height == 1
        l, m, r = string.((l, m, r))
    end

    # create row
    # @info "row" Measure(cells[1]) Measure(m) cells[1]*m
    mid = if length(widths) > 1
        l * foldl((a, b) -> a * m * b, cells[1:end]) * r
    else
        l * cells[1] * r
    end
    bottom = apply_style(get_row(box, widths, bottom_level), box_style)

    return if !isnothing(top_level)
        string(vstack(apply_style(get_row(box, widths, top_level), box_style), mid, bottom))
    else
        string(compact ? mid : vstack(mid, bottom))
    end
end

"""
    cell(x::AbstractString, hor_pad::Int, h::Int, w::Int, justify::Symbol, style::String, vertical_justify::Symbol)

Create a Table's row's cell from a string - apply styling and vertical/horizontal justification.
"""
function cell(
    x::AbstractString,
    hor_pad::Int,
    h::Int,
    w::Int,
    justify::Symbol,
    style::String,
    vertical_justify::Symbol,
)
    content = do_by_line(
        y -> apply_style(" " * pad(y, w - 2, justify) * " ", style),
        str_trunc(x, w - hor_pad),
    )
    return vertical_pad(content, h, vertical_justify)
end

"""
    cell(x::AbstractString, hor_pad::Int, h::Int, w::Int, justify::Symbol, style::String, vertical_justify::Symbol)

Create a Table's row's cell from a renderable - apply styling and vertical/horizontal justification.
"""
cell(
    x::AbstractRenderable,
    hor_pad::Int,
    h::Int,
    w::Int,
    justify::Symbol,
    style::String,
    vertical_justify::Symbol,
) = vertical_pad(do_by_line(y -> pad(y, w, justify), string(x)), h, vertical_justify)

"""
    make_row_cells(
        entries::Union{Tuple, Vector}, 
        style::Vector{String}, 
        justify::Vector{Symbol},
        widths::Vector{Int},
        height::Int, 
        vertical_justify::Symbol,
    ) 

Create a row's cell from a vector of 'entries' (renderables or strings).
"""
make_row_cells(
    entries::Union{Tuple,Vector},
    style::Vector{String},
    justify::Vector{Symbol},
    widths::Vector{Int},
    hor_pad::Vector{Int},
    height::Int,
    vertical_justify::Symbol,
) = map(
    i -> cell(
        entries[i],
        hor_pad[i],
        height,
        widths[i],
        justify[i],
        style[i],
        vertical_justify,
    ),
    1:length(entries),
)

end
