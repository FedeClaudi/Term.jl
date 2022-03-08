# Colors
Okay, so far so good. We can use macros like `@red` and the `tprint` function to print colored strings. But so far we've only been using few named colors (blue, red...) and 

```@example
function rainbow_maker() # hide
    text = "there's a whole rainbow\n of colors out there"

    _n = Int(length(text)/2)
    R = hcat(range(30, 255, length=_n), range(255, 60, length=_n))
    G =hcat(range(255, 60, length=_n), range(60, 120, length=_n))
    B = range(50, 255, length=length(text))

    out = ""
    for n in 1:length(text)
        r, g, b = R[n], G[n], B[n]
        out *= "[($r, $g, $b)]$(text[n])[/($r, $g, $b)]"
    end

    return out
end # hide

import Term: tprint  # hide
tprint(rainbow_maker()) # hide
```