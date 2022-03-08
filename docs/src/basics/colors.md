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

so how can we use different kinds of colors?
It's all done through `Term`'s markup syntax of course. Look:
```@example
using Term: tprint # hide
tprint("[(255, 50, 100)]colors![/(255, 50, 100)]")
```

yep, you can pass a set of `(r, g, b)` values and that'll do it. Personally, I prefer working with hex codes, and so `Term` can accept them too:
```@example
using Term: tprint # hide
indigo = "#42A5F5"

tprint("Some [$indigo]color![/$indigo]")
```

## Under the hood
What `Term` is doing here is taking each bit of style information in the markup tag (each word or each `(...)` within `[...]`) and constructing style codes with an `ANSICode` object.
If the style informaton represents a color, `Term` first represents it as a `AbstractColor` type: `NamedColor` or `BitColor` or `RGBColor`.  `NamedColor` objects represent simple colors like `red` and `blue`, `BitColor` represnt 16-bit colors like `dark_goldenrod` and `RGBColor`, surprisingly, represents rgb-style colors. There's no method to represent hex colors as these are converted into rgb first. 

The distinction between `NamedColor`, `BitColor` and `RGBColor` is necessary because three color styles are represented by a different syntax in the ANSI codes. Naturally, `Term` users won't normally worry about this and can use whichever color formulation is most convenient.
