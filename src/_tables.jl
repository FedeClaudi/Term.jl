"""
    columns_widths

Get the width of each column in a `Table`.

If user passed a `columns_widths` argument use that, otherwise
compute the width of each column based on the size of its contents
including the header and footer.
"""
function calc_columns_widths(
    N_cols::Int,
    N_rows::Int,
    columns_widths::Union{Nothing,Vector,Int},
    show_header::Bool,
    header::Union{Tuple,AbstractVector,String,Nothing},
    tb::TablesPkg.AbstractColumns,
    sch,  # table schema
    footer::Union{Tuple,AbstractVector,String,Nothing},
    hpad::Union{Nothing,Int,AbstractVector},
)
    if !isnothing(columns_widths)
        columns_widths = expand(columns_widths, N_cols)
        return columns_widths
    end

    headers_widths = show_header ? collect(width.(header)) : zeros(N_cols)
    data_widths = collect(map(c -> max(width.(tb[c])...), sch.names))
    footers_widths = isnothing(footer) ? zeros(N_cols) : collect(width.(footer))
    widths = hcat(headers_widths, data_widths, footers_widths)

    hpad = isa(hpad, Int) ? fill(hpad, N_rows) : hpad
    widths = Int.([mapslices(x -> max(x...), widths; dims = 2)...] .+ hpad * 2)
    return widths
end

"""
    rows_heights

Get the height of each row in a `Table`
"""
function rows_heights(N_rows::Int, show_header::Bool, header, rows_values, footer, vpad)
    headers_height = show_header ? max(height.(header)...) : 0
    data_heights = collect(map(r -> max(height.(r)...), rows_values))
    footers_height = isnothing(footer) ? 0 : max(height.(footer)...)
    vpad = isa(vpad, Int) ? fill(vpad, N_rows) : vpad
    heights = [headers_height, data_heights..., footers_height] .+ vpad .* 2
    return heights
end

"""
    expand

Expand single `Table` arguments into a vector if necessary.
"""
expand(v::Vector, N::Int) = v
expand(v::Union{Symbol,String,Int}, N::Int) = fill(v, N)

"""
    assert_table_arguments

Check that arguments passed to `Table` match the Table's shape.
Single arguments are fine, but when a vector is passed it should have the appropriate size.
"""
function assert_table_arguments(
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
    # check header
    problems = []
    if !isnothing(header) && show_header
        length(header) != N_cols &&
            push!(problems, "Got header with length $(length(header)), expected $N_cols")
        (!isa(header_style, String) && length(header_style) != N_cols) && push!(
            problems,
            "Got header_style with length $(length(header_style)), expected $N_cols",
        )
        (!isa(header_justify, Symbol) && length(header_justify) != N_cols) && push!(
            problems,
            "Got header_justify with length $(length(header_justify)), expected $N_cols",
        )
    end

    # check columns
    (!isa(columns_style, String) && length(columns_style) != N_cols) && push!(
        problems,
        "Got columns_style with length $(length(columns_style)), expected $N_cols",
    )
    (!isa(columns_justify, Symbol) && length(columns_justify) != N_cols) && push!(
        problems,
        "Got columns_justify with length $(length(columns_justify)), expected $N_cols",
    )
    columns_widths isa Vector &&
        length(columns_widths) != N_cols &&
        push!(
            problems,
            "Got columns_widths with length $(length(columns_widths)), expected $N_cols",
        )

    # check footer
    if !isnothing(footer)
        isa(footer, Function) ||
            (length(footer)) != N_cols && push!(
                problems,
                "Got footer with length $(length(footer)), expected $N_cols",
            )
        (!isa(footer_style, String) && length(footer_style) != N_cols) && push!(
            problems,
            "Got footer_style with length $(length(footer_style)), expected $N_cols",
        )
        (!isa(footer_justify, Symbol) && length(footer_justify) != N_cols) && push!(
            problems,
            "Got footer_justify with length $(length(footer_justify)), expected $N_cols",
        )
    end

    # check hpad
    (!isa(hpad, Int) && length(hpad) != N_cols) &&
        push!(problems, "Got hpad with length $(length(hpad)), expected $N_cols")
    (!isa(vpad, Int) && length(vpad) != N_rows) &&
        push!(problems, "Got vpad with length $(length(vpad)), expected $N_rows")

    # if there were problems, alert user and fail gracefully
    if length(problems) > 0
        @warn "Failed to create Term.Table"
        warn_color = "yellow_light"
        tprintln.("  {$warn_color}" .* problems .* "{/$warn_color}"; highlight = true)
    end
    return length(problems) == 0
end
