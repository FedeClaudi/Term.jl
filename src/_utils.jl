int(x) = (Int ∘ round)(x)
fint(x) = (Int ∘ floor)(x)
cint(x) = (Int ∘ ceil)(x)

"""
  loop_last(v::Vector)

  Returns an iterable yielding tuples (is_last, value).
"""
function loop_last(v::Vector)
    is_last = [i == length(v) for i in 1:length(v)]
    return zip(is_last, v)
end

"""
  get_lr_widths(width::Int)

To split something with `width` in 2, get the lengths
of the left/right widths.

When width is even that's easy, when it's odd we need to
be careful.
"""
function get_lr_widths(width::Int)::Tuple{Int, Int}
  iseven(width) && return (int(width/2), int(width/2))
  return (fint(width/2), cint(width/2))
end