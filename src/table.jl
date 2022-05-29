module table
    using Tables

    import ..measure: Measure, width, height
    import ..segment: Segment
    import ..renderables: AbstractRenderable, RenderableText
    import ..layout: cvstack, hstack, vstack, pad
    using ..box

    export Table

    mutable struct Table <: AbstractRenderable
        segments::Vector{Segment}
        measure::Measure
        # header::Vector
        # data
    end


    rtexts(x) = RenderableText.(string.(x))


    function table_row(cells, widths, box, top_level, mid_level, bottom_level)
        # get box characters
        mid_level = getfield(box, mid_level)
        l, m, r = mid_level.left, mid_level.vertical, mid_level.right

        # padd cell elements to correct width
        cells = map(
            c -> pad(c[2], widths[c[1]], :center),
            enumerate(cells)
        )

        # create row
        mid = l * join(
            cells[1:end-1], m
        ) * m * cells[end] * r
        bottom = get_row(box, widths, bottom_level)

        if !isnothing(top_level)
            top = get_row(box, widths, top_level)
            return string(vstack(top, mid, bottom))
        else
            return string(vstack(mid, bottom))
        end

    end


    function Table(tb::Tables.AbstractColumns;
            box = :SQUARE,
        )
        box = eval(box)

        rows = Tables.rows(tb) 
        sch = Tables.schema(rows)

        # get the width of each column
        widths = collect(map(
            c -> max(width(c), width.(tb[c])...), sch.names
        )) .+ 2

        rows_values = collect(map(
            r -> collect(map(
                c -> string.(r[c]), sch.names
            )), rows
        ))

        # create table lines
        nrows = length(rows_values)
        lines::Vector{String} = [table_row(string.(sch.names), widths, box, :top, :head, :head_row),]

        for (l, row) in enumerate(rows_values)
            if l == 1
                bottom = nrows < 2 ? :bottom : nrows > 2 ? :foot_row : :row
                push!(lines,
                    table_row(row, widths, box, nothing, :mid, bottom)
                )
            elseif l == nrows - 1
                push!(lines, 
                    table_row(row, widths, box, nothing, :mid, :foot_row)
                )
            elseif l == nrows
                push!(lines, 
                    table_row(row, widths, box, nothing, :foot, :bottom)
                )
            else
                push!(lines, 
                    table_row(row, widths, box, nothing, :mid, :row)
                )
            end
        end

        segments = Segment.(lines)
        return Table(segments, Measure(segments))
    end

    Table(data::AbstractMatrix; kwargs...) = Table(Tables.table(data); kwargs...)

end