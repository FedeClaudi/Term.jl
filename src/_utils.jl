rint(x) = (Int ∘ round)(x)
fint(x) = (Int ∘ floor)(x)
cint(x) = (Int ∘ ceil)(x)

is_last(v) = eachindex(v) .== lastindex(v)
is_first(v) = eachindex(v) .== firstindex(v)

"""
  loop_last(v)

  Returns an iterable yielding tuples (is_last, value).
"""
loop_last(v) = zip(is_last(v), v)

loop_firstlast(v) = zip(is_first(v), is_last(v), v)

"""
  get_lr_widths(width::Int)

To split something with `width` in 2, get the lengths
of the left/right widths.

When width is even that's easy, when it's odd we need to
be careful.
"""
function get_lr_widths(width::Int)::Tuple{Int,Int}
    iseven(width) && return (rint(width / 2), rint(width / 2))
    return (fint(width / 2), cint(width / 2))
end

"""
Get a clean string representation of an expression
"""
expr2string(e::Expr) = replace_multi(
    string(e),
    '\n' => "",
    ' ' => "",
    r"#=.*=#" => "",
    "begin" => "",
    "end" => "",
)

"""
  get_file_format(nbytes; suffix="B")

Return a string with formatted file size.
"""
function get_file_format(nbytes; suffix = "B")
    for unit in ("", "K", "M", "G", "T", "P", "E", "Z", "Y")
        nbytes < 1024 && return string(round(nbytes; digits = 2), ' ', unit, suffix)
        nbytes = nbytes / 1024
    end
end

"""
    calc_nrows_ncols(n, aspect::Union{Nothing,Number,NTuple} = nothing)

Computes the number of rows and columns to fit a given number `n` of subplots in a figure with aspect `aspect`.
If `aspect` is `nothing`, chooses the best fir between a default and a unit aspect ratios.

Adapted from: stackoverflow.com/a/43366784
"""
function calc_nrows_ncols(n, aspect::Union{Nothing,Number,NTuple} = nothing)
    h, w = if isnothing(aspect)
        r1, c1 = calc_nrows_ncols(n, DEFAULT_ASPECT_RATIO[])
        r2, c2 = calc_nrows_ncols(n, 1)  # unit aspect - square
        return r1 * c1 < r2 * c2 ? (r1, c1) : (r2, c2)  # choose the best fit
    elseif aspect isa Number
        (one(aspect), aspect)
    else
        aspect
    end
    factor = √(n / (h * w))
    rows = floor(Int, h * factor)
    cols = floor(Int, w * factor)
    row_first = w < h
    while rows * cols < n
        if row_first
            rows += 1
        else
            cols += 1
        end
        row_first = !row_first
    end
    return rows, cols
end

"""
    get_bg_color(style::String)

Add "on_" to background style info.
"""
get_bg_color(style::String) = startswith(style, "on_") ? style : "on_" * style
get_bg_color(style::Nothing) = style
