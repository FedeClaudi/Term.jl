# Term

Implementing some functionality of the awesome [Rich](https://github.com/Textualize/rich) python library in Julia.
While I've been writing this library, most of the credit goes to Will McGugan who has done an incredible work developing `rich`.
My contribution is a translation of some of `rich`'s base featurs in Julia.

NODE: this project is in very early development. There will be frequent breaking changes. Use at your own peril


## Features

Most features are barely implemented and buggy so far.

### `tprint`
`Term.tprint` prits stylized text (and any `AbstractRenderable`)

### Markup text
Give a string with markup text:
```
"normal text [red bold]this text will be red and bold[/red bold] this text is also normal"
```
`Term.MarkupText` injects ANSI codes to edit the style of the text printed to terminal.

### Box
`Term.box.Box` represents collections of characters to produce box-like text objects (e.g. panel below)


### Panel
Create a panel (a box) around a string or other `AbstractRenderable`, styling the panel's box and content
```julia
test = """
[black on_white]First line[/black on_white]
second line, both in the panel!"""

panel = Panel(test; style="green", width=40, justify=:left);
tprint(panel)


panel = Panel(test; style="white", width=40, justify=:center, box=:SQUARE);
tprint(panel)


panel = Panel(test; style="red", width=40, justify=:right);
tprint(panel)
```

gives
![](docs/images.jl/panel.png)

## BUGS
- COLORS
  - [ ] passing only `mode` or `background` to a markup tag causes all colors to change
  - [ ] most colors passed to `markup` tags are not rendered or incorrectly rendered

## TODO
  - COLOR
    - [ ] hex/rgb -> color code, compatibility with MyterialColors.jl
    - [ ] if bg is passed and front color is not, infer front color to make bg work
    - [ ] check that colors actually work correctly

- MARKUP
    - [x] escaping [] from strings
    - [ ] autoclose tags with [/] or end of string
    - [x] allow for nested tags
      - [ ] correct ANSI code reset for nested tags with > 1 levels
      - [ ] fix bug for >1 levels of nested tags
    - [ ] multi-line markup strings

- PANEL
  - add title
