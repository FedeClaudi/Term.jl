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
  is_last =  1:length(v) .== length(v)
    return zip(is_last, v)
end


function loop_firstlast(v)
  is_first =  1:length(v) .== 1
  is_last =  1:length(v) .== length(v)
  return zip(is_first, is_last, v)
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