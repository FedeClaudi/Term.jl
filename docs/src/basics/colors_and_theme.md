# Colors
Okay, so far so good. We can use macros like `@red` and the `tprint` function to print colored strings. But so far we've only been using few named colors, but..

```@example
import Term: rint, tprint # hide
function rainbow_maker() # hide
    text = "there's a whole rainbow\n of colors out there" # hide
    _n = Int(length(text)/2)  # hide
    R = hcat(range(30, 255, length=_n), range(255, 60, length=_n))  # hide
    G =hcat(range(255, 60, length=_n), range(60, 120, length=_n))  # hide
    B = range(50, 255, length=length(text))  # hide
    out = ""  # hide
    for n in 1:length(text)  # hide
        r, g, b = rint(R[n]), rint(G[n]), rint(B[n])  # hide
        out *= "{($r, $g, $b)}$(text[n]){/($r, $g, $b)}"  # hide
    end # hide
    return out  # hide
end # hide
tprint(rainbow_maker(); highlight=false) # hide
```

so how can we use different kinds of colors?
It's all done through `Term`'s markup syntax of course. Look:
```@example
using Term: tprint # hide
tprint("{(255, 50, 100)}colors!{/(255, 50, 100)}"; highlight=false)
```

yep, you can pass a set of `(r, g, b)` values and that'll do it. Personally, I prefer working with hex codes, and so `Term` can accept them too:
```@example
using Term: tprint # hide
indigo = "#42A5F5"

tprint("Some {$indigo}color!{/$indigo}"; highlight=false)
```

## Under the hood
What `Term` is doing here is taking each bit of style information in the markup tag (each word or each `(...)` within `{...}`) and constructing style codes with an `ANSICode` object.

If the style information represents a color, `Term` first represents it as a `AbstractColor` type: `NamedColor` or `BitColor` or `RGBColor`.  

`NamedColor` objects represent simple colors like `red` and `blue`, `BitColor` represent 16-bit colors like `dark_goldenrod` and `RGBColor`, surprisingly, represents rgb-style colors. There's no method to represent hex colors as these are converted into rgb first. 

The distinction between `NamedColor`, `BitColor` and `RGBColor` is necessary because the three color styles are represented by a different syntax in the ANSI codes. Naturally, `Term` users won't normally worry about this and can use whichever color formulation is most convenient.


# [Theme](@id ThemeDocs)
Term defines a `Theme` type that carries styling information used throughout. 
It tells `highlight` what color things should be, it stores the colors of elements of [Tree](@ref TreeDoc), and of the [Repr functionality](@ref ReprDoc).

```@example theme
import Term: Theme, set_theme, TERM_THEME

default = TERM_THEME[]
```

You can create a new theme with different colors:
```@example theme
newtheme = Theme(string="red", code="black on_white")
```

and set it as the new theme to be used by Term:
```@example theme
set_theme(newtheme)
```

```@example theme
set_theme(Theme()) # hide
```


The default theme used by `Term` is tailored for a dark terminal, if you fancy a lighter terminal experience, you might want to:
```julia
import Term: set_theme, LightTheme

set_theme(LightTheme)
```