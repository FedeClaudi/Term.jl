int(x) = (Int ∘ round)(x)
fint(x) = (Int ∘ floor)(x)
cint(x) = (Int ∘ ceil)(x)

"""
  or(x, y)

Return `y` if `x` is `Nothing`
"""
or(x, y) = isnothing(x) ? y : x

"""
  loop_last(v)

  Returns an iterable yielding tuples (is_last, value).
"""
function loop_last(v)
    is_last = 1:length(v) .== length(v)
    return zip(is_last, v)
end

function loop_firstlast(v)
    is_first = 1:length(v) .== 1
    is_last = 1:length(v) .== length(v)
    return zip(is_first, is_last, v)
end

"""
  get_lr_widths(width::Int)

To split something with `width` in 2, get the lengths
of the left/right widths.

When width is even that's easy, when it's odd we need to
be careful.
"""
function get_lr_widths(width::Int)::Tuple{Int,Int}
    iseven(width) && return (int(width / 2), int(width / 2))
    return (fint(width / 2), cint(width / 2))
end

"""
Get a clean string representation of an expression
"""
expr2string(e::Expr) = replace_multi(
    string(e), '\n' => "", ' ' => "", r"#=.*=#" => "", "begin" => "", "end" => ""
)

"""
  get_file_format(nbytes; suffix="B")

Return a string with formatted file size.
"""
function get_file_format(nbytes; suffix = "B")
    for unit in ["", "K", "M", "G", "T", "P", "E", "Z", "Y"]
        if nbytes < 1024.0
            _nd = round(nbytes; digits = 2)
            return string(_nd) * " $unit$suffix"
        end
        nbytes = nbytes / 1024.0
    end
    return "cacca"
end

"""
    calc_nrows_ncols(n, aspect=(16, 9))

Computes the number of rows and columns to fit a given number `n` of subplots in a figure with aspect `aspect`.
Adapted from: stackoverflow.com/a/43366784
"""
function calc_nrows_ncols(n, aspect::Union{Number,NTuple} = (16, 9))
    w, h = if aspect isa Number
        (aspect, one(aspect))
    else
        aspect
    end
    factor = √(n / (w * h))
    cols = floor(Int, w * factor)
    rows = floor(Int, h * factor)
    rowFirst = w < h
    while rows * cols < n
        if rowFirst
            rows += 1
        else
            cols += 1
        end
        rowFirst = !rowFirst
    end
    return rows, cols
end
