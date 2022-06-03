module Tables

import Tables as TablesPkg

import Term: do_by_line, term_theme, fillin, truncate
import MyterialColors: orange

import ..Renderables: AbstractRenderable, RenderableText
import ..Layout: cvstack, hstack, vstack, pad, vLine, vertical_pad
import ..Measures: Measure, width, height
import ..Style: apply_style
import ..Segments: Segment
import ..Tprint: tprintln
using ..Boxes

export Table

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
        hpad::Union{Vector, Int}=2,
        vpad::Union{Vector, Int}=0,
        vertical_justify::Symbol=:center,

        show_header::Bool = true,
        header::Union{Nothing, Vector, Tuple}=nothing,
        header_style::Union{String, Vector, Tuple} = "default",
        header_justify::Union{Nothing, Symbol, Vector, Tuple} = nothing,
        
        columns_style::Union{String, Vector, Tuple} = "default",
        columns_justify::Union{Symbol, Vector, Tuple} = :center,

        footer::Union{Function, Nothing, Vector, Tuple}=nothing,
        footer_style::Union{String, Vector, Tuple} = "default",
        footer_justify::Union{Nothing, Symbol, Vector, Tuple} = :center
    )

Generic constructo for a Table renderable.
"""
function Table(
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

    # prepare some variables
    header_justify = isnothing(header_justify) ? columns_justify : header_justify
    box = eval(box)

    # table info
    rows = TablesPkg.rows(tb)
    sch = TablesPkg.schema(rows)
    N_cols = length(sch.names)
    N_rows = length(rows) + 2

    # make sure arguemnts combination is valud
    valid = assert_table_arguments(
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
    )
    valid || return nothing

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
            footer = repeat(["couldn't apply"], N_cols)
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
    # @info "sizes" widths heights    

    # create table lines
    nrows = length(rows_values)
    lines::Vector{String} = []
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
            heights[1],
        ),
    )

    for (l, row) in enumerate(rows_values)
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
        if l == 1
            bottom = if nrows < 2
                :bottom
            elseif nrows > 2
                :row
            else
                :foot_row
            end
            push!(
                lines,
                table_row(
                    row,
                    widths,
                    box,
                    show_header ? nothing : :top,
                    :mid,
                    bottom,
                    style,
                    heights[I];
                    compact = show_header ? false : compact,
                ),
            )
        elseif l == nrows
            push!(
                lines,
                table_row(
                    row,
                    widths,
                    box,
                    nothing,
                    :mid,
                    isnothing(footer) ? :bottom : :foot_row,
                    style,
                    heights[I],
                ),
            )
        else
            push!(
                lines,
                table_row(
                    row,
                    widths,
                    box,
                    nothing,
                    :mid,
                    :row,
                    style,
                    heights[I];
                    compact = compact,
                ),
            )
        end
    end

    if !isnothing(footer)
        # get footer style
        footer_justify = isnothing(footer_justify) ? columns_justify : footer_justify
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
function Table(data::Union{AbstractVector,AbstractMatrix}; kwargs...)
    return Table(TablesPkg.table(data); kwargs...)
end

""" 
Table(data::AbstractDict; kwargs...)

Construct `Table` from a `Dict`.
The Dict's keys make up the table header if none is assigned.
"""
function Table(data::AbstractDict; kwargs...)
    kwargs = Dict(kwargs...)
    header = pop!(kwargs, :header, string.(collect(keys(data))))

    data = hcat(values(data)...)
    return Table(data; header = header, kwargs...)
end

"""
    table_row(cells, widths, box, top_level, mid_level, bottom_level, box_style, row_height)

Create a single row of a `Table` renderable. 

Each row is made up of an upper, mid and bottom section. The
upper and bottom sections are created by rows of the `Box` type.
The mid section is made up of the row's cells and dividing lines.
"""
function table_row(
    cells,
    widths,
    box,
    top_level,
    mid_level,
    bottom_level,
    box_style,
    row_height;
    compact = false,
)
    # get box characters
    mid_level = getfield(box, mid_level)

    l = vLine(row_height; style = box_style, char = mid_level.left)
    m = vLine(row_height; style = box_style, char = mid_level.vertical)
    r = vLine(row_height; style = box_style, char = mid_level.right)

    if row_height == 1
        l, m, r = string(l), string(m), string(r)
    end

    # create row
    if length(widths) > 1
        mid = l * foldl((a, b) -> a * m * b, cells[1:end]) * r
    else
        mid = l * cells[1] * r
    end
    bottom = apply_style(get_row(box, widths, bottom_level), box_style)

    if !isnothing(top_level)
        top = apply_style(get_row(box, widths, top_level), box_style)
        return string(vstack(top, mid, bottom))
    else
        return compact ? string(mid) : string(vstack(mid, bottom))
    end
end

"""
    cell(x::AbstractString, w::Int, h::Int, justify::Symbol, style::String, vertical_justify::Symbol)

Create a Table's row's cell from a string - apply styling and vertical/horizontal justification.
"""
function cell(
    x::AbstractString,
    w::Int,
    hor_pad::Int,
    h::Int,
    justify::Symbol,
    style::String,
    vertical_justify::Symbol,
)
    return vertical_pad(
        do_by_line(
            y -> apply_style(" " * pad(y, w - 2, justify) * " ", style),
            truncate(x, w - hor_pad),
        ),
        h,
        vertical_justify,
    )
end

"""
    cell(x::AbstractString, w::Int, h::Int, justify::Symbol, style::String, vertical_justify::Symbol)

Create a Table's row's cell from a renderable - apply styling and vertical/horizontal justification.
"""
function cell(
    x::AbstractRenderable,
    w::Int,
    hor_pad::Int,
    h::Int,
    justify::Symbol,
    style::String,
    vertical_justify::Symbol,
)
    return vertical_pad(do_by_line(y -> pad(y, w, justify), string(x)), h, vertical_justify)
end

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
function make_row_cells(
    entries::Union{Tuple,Vector},
    style::Vector{String},
    justify::Vector{Symbol},
    widths::Vector{Int},
    hor_pad::Vector{Int},
    height::Int,
    vertical_justify::Symbol,
)
    N = length(entries)
    cells = map(
        i -> cell(
            entries[i],
            widths[i],
            hor_pad[i],
            height,
            justify[i],
            style[i],
            vertical_justify,
        ),
        1:N,
    )
    return cells
end

end
