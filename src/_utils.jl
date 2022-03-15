int(x) = (Int ∘ round)(x)

"""
  loop_last(v::Vector)

  Returns an iterable yielding tuples (is_last, value).
"""
function loop_last(v::Vector)
    is_last = [i == length(v) for i in 1:length(v)]
    return zip(is_last, v)
end