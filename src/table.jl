module table
    using Tables

    import ..measure: Measure, width, height
    import ..segment: Segment
    import ..renderables: AbstractRenderable, RenderableText
    import ..layout: cvstack, hstack, vstack, pad
    using ..box
    import ..style: apply_style
    import ..Tprint: tprintln
    import Term: fillin, term_theme

    export Table

    mutable struct Table <: AbstractRenderable
        segments::Vector{Segment}
        measure::Measure
    end


    function table_row(cells, widths, box, top_level, mid_level, bottom_level, box_style)
        # get box characters
        mid_level = getfield(box, mid_level)
        l, m, r = mid_level.left, mid_level.vertical, mid_level.right
        l, m, r = apply_style(l, box_style), apply_style(m, box_style), apply_style(r, box_style)

        # pad cell elements to correct width
        cells = map(
            c -> pad(c[2], widths[c[1]], :center),
            enumerate(cells)
        )

    

        # create row
        if length(widths) > 1
            mid = l * join(
                cells[1:end-1], m
            ) * m * cells[end] * r
        else
            mid = l * cells[1] * r
        end
        bottom = apply_style(get_row(box, widths, bottom_level), box_style)

        if !isnothing(top_level)
            top = apply_style(get_row(box, widths, top_level), box_style)
            return string(vstack(top, mid, bottom))
        else
            return string(vstack(mid, bottom))
        end

    end


    function make_cells_entries(
            entries::Union{Tuple, Vector}, 
            style::Vector{String}, 
            justify::Vector{Symbol},
            widths::Vector{Int}
        )
        N = length(entries)

        cells = map(
            i -> apply_style(
                pad(entries[i], widths[i], justify[i]),style[i]
            ), 1:N
        )
        return cells
    end

    function expand_styles(N::Int, style::Union{Vector, String}, justify::Union{Vector, Symbol})
        style = style isa String ? repeat([style], N) : style
        justify = justify isa Symbol ? repeat([justify], N) : justify
        return style, justify
    end

    function assert_table_arguments(N, header, header_style, header_justify, columns_style, columns_justify, footer, footer_style, footer_justify)
        # check header
        problems = []
        if !isnothing(header)
            length(header) != N && push!(problems, "Got header with length $(length(header)), expected $N")
            (!isa(header_style, String) && length(header_style) != N) && push!(problems, "Got header_style with length $(length(header_style)), expected $N")
            (!isa(header_justify, Symbol) && length(header_justify) != N) && push!(problems, "Got header_justify with length $(length(header_justify)), expected $N")
        end

        # check columns
        (!isa(columns_style, String) && length(columns_style) != N) && push!(problems, "Got columns_style with length $(length(columns_style)), expected $N")
        (!isa(columns_justify, Symbol) && length(columns_justify) != N) && push!(problems, "Got columns_justify with length $(length(columns_justify)), expected $N")


        # check footer
        if !isnothing(footer)
            isa(footer, Function) || (length(footer)) != N && push!(problems, "Got footer with length $(length(footer)), expected $N")
            (!isa(footer_style, String) && length(footer_style) != N) && push!(problems, "Got footer_style with length $(length(footer_style)), expected $N")
            (!isa(footer_justify, Symbol) && length(footer_justify) != N) && push!(problems, "Got footer_justify with length $(length(footer_justify)), expected $N")
        end

        if length(problems) > 0
            @warn "Failed to create Term.Table"
            warn_color = term_theme[].warn
            tprintln.("  {$warn_color}" .* problems .* "{/$warn_color}"; highlight=true)
        end
        return length(problems) == 0
    end

    function Table(
            tb::Tables.AbstractColumns;
            box::Symbol = :SQUARE,
            style::String = "default",
            padding::Int=2,

            header::Union{Nothing, Vector, Tuple}=nothing,
            header_style::Union{String, Vector, Tuple} = "default",
            header_justify::Union{Nothing, Symbol, Vector, Tuple} = nothing,
            
            columns_style::Union{String, Vector, Tuple} = "default",
            columns_justify::Union{Symbol, Vector, Tuple} = :center,

            footer::Union{Function, Nothing, Vector, Tuple}=nothing,
            footer_style::Union{String, Vector, Tuple} = "default",
            footer_justify::Union{Nothing, Symbol, Vector, Tuple} = :left
        )
        # @info "GENERATING TABLE" tb box header footer make_cells_entries
        # prepare some variables
        header_justify = isnothing(header_justify) ? columns_justify : header_justify
        box = eval(box)

        # table info
        rows = Tables.rows(tb) 
        sch = Tables.schema(rows)
        N_cols = length(sch.names)

        # make sure arguemnts combination is valud
        valid = assert_table_arguments(N_cols, header, header_style, header_justify, columns_style, columns_justify, footer, footer_style, footer_justify)
        valid || return

        # columns style
        columns_style, columns_justify = expand_styles(N_cols, columns_style, columns_justify)

        # headers and headers style
        header = isnothing(header) ? string.(sch.names) : header
        header_style, header_justify = expand_styles(N_cols, header_style, header_justify)

        # get footer (if it's a function)
        if footer isa Function
            footer = string(footer) * ": " .* string.(footer.(map(c -> tb[c], sch.names)))
        end

        # get the max-width of each column
        headers_widths = collect(width.(header))
        data_widths = collect(map(c -> max(width.(tb[c])...), sch.names))
        footers_widths = isnothing(footer) ? zeros(N_cols) : collect(width.(footer))
        # @info "widths" headers_widths data_widths footers_widths sch.names

        widths = hcat(headers_widths, data_widths, footers_widths)
        widths = Int.([mapslices(x -> max(x...), widths, dims=2)...] .+ padding * 2)
        @info "widths" widths

        # get the table values as vectors of strings
        rows_values = collect(map(
            r -> collect(map(
                c -> string.(r[c]), sch.names
            )), rows
        ))

        # create table lines
        nrows = length(rows_values)
        lines::Vector{String} = [
            table_row(
                make_cells_entries(header, header_style, header_justify, widths), 
                widths, box, :top, :head, :head_row, style),
        ]

        for (l, row) in enumerate(rows_values)
            row = make_cells_entries(row, columns_style, columns_justify, widths)
            if l == 1
                bottom = nrows < 2 ? :bottom : nrows > 2 ? :row : :foot_row
                push!(lines,
                    table_row(row, widths, box, nothing, :mid, bottom, style)
                )
            elseif l == nrows
                push!(lines, 
                    table_row(row, widths, box, nothing, :mid, isnothing(footer) ? :bottom : :foot_row, style)
                )
            else
                push!(lines, 
                    table_row(row, widths, box, nothing, :mid, :row, style)
                )
            end
        end

        if !isnothing(footer)
            # get footer style
            footer_justify = isnothing(footer_justify) ? columns_justify : footer_justify
            footer_style, footer_justify = expand_styles(N_cols, footer_style, footer_justify)

            push!(lines,
                table_row(
                    make_cells_entries(footer, footer_style, footer_justify, widths),
                    widths, box, nothing, :foot, :bottom, style)
            )
        end

        lines = split(fillin(join(lines, "\n")), "\n")

        segments = Segment.(lines)
        return Table(segments, Measure(segments))
    end

    Table(data::AbstractMatrix; kwargs...) = Table(Tables.table(data); kwargs...)
    Table(data::AbstractVector; kwargs...) = Table(Tables.table(data); kwargs...)

    function Table(data::AbstractDict; kwargs...)
        kwargs = Dict(kwargs...)
        header = pop!(kwargs, :header, string.(collect(keys(data))))
        
        data = hcat(values(data)...)
        # @info "dict2table" kwargs header data
        return Table(data; header=header, kwargs...)
    end

end