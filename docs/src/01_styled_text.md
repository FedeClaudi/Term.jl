# Styled text
The term `styled text` refers to text printed out to a terminal (or other `::IO`) with either color or other style (e.g., bold, italic) information. This is done by adding `ANSI` escape sequences in a string being printed to the terminal. These escape sequences are not rendered as caracters but add the style information.

## Style macros
The easiest way to add style information to a `String` in `Term` is using the dedicated macros:

```@example
using Term
println(@green "this is green")
println(@blue "and this is blue")
print("\n")
println(@bold "this is bold")
println(@underline "and this is underlined")
```

For color you can use these macros: `@black, @red, @green, @yellow, @blue, @magenta, @cyan, @white, @default`.
While for styling you have: `@bold @dim @italic @underline`.

Note that the styling macros return a string, so you can combine the resulting strings as you would normally:

```@example
using Term # hide
println(
    @green("This is green") * " and " * @red("this is red")
)
println(
    "Make your text $(@underline("stand out"))!"
)
```

With these style macros you can do some simply styling, but it gets clunky when you want to go beyond adding some color. Let's say you want you text to be blue, bold and underlined; do you really need to use three macros?

Of course not, you can use the `@style` macro!

```@example
using Term # hide
mytext = @style "this is my text" blue bold underline
println(mytext)
```

Like the macros you already know, `@style` returns a string with the desired style, except that now you can specify multiple styles at once! 

## Markup text
The basic styling macros are great for handling simple cases where you just want to add a bit of style to a piece of text. More realistically, you might want more control about exactly which parts of your text have what style. 

As a way of example, let's say you want every other word of yours string:

```julia
str="Every other word has colors!"
```

to have a color. You could do it with macros:

```@example
using Term # hide
e = @red "Every"
o = "other"
w = @green "word"
h = "has"
c = @blue "colors!"

print(join((e, o, w, h, c), " "))
```

but that's awful. String [interpolation](https://docs.julialang.org/en/v1/manual/strings/#string-interpolation) would also not be of much help here. Instead, it would be great if we could specify styles directly inside a normal string and let `Term` figure it out.

Well, that's exactly what we're going to do:
```@example
import Term: tprint
tprint(
    "[red]Every[/red] other [green]word[/green] has [blue]colors![/blue]"
)
```

Woah! What just happened!!
Two things happened: 1) `Term` styling machinery detects strings segments like `"[red]Every[/red]"` as meaning that the text between `"[...]"` and `"[/...]"` should be colored red and 2) `tprint` (short for term print) detects this style information and applies it to your text before printing. 

Not bad huh? Even better, the style information inside a parentheses can be more than just color:
```@example
using Term # hide
tprint(
    "[bold black underline on_red]So much [gold3 bold]STYLE[/gold3 bold] in this text[/bold black underline on_red]"
)
```
that's right, `Term.jl` can also color the background of your text (by adding `on_C` to your color `C` you set it as the background, see !!!! COLORS !!! page). Also, you might have noticed, `Term` can also handle nested style tags!

If you just want to **use** `Term.jl`'s style functionality, just make sure to read the admonition below. If you're curious about what's happening under the hood, read on below!

!!! warning "A note on style tags"
    The style tags used by `Term.jl` have an opening `"[style]"` and closing `"[/style]"` syntax. The style is applied to everything inbetween. For `"[/style]"` to close `"[style]"` the text in the parentheses must match exactly (excuding `/`), up to the number and position of spaces and the words order. So:
    ```julia
    "[red] wohoo [/red]"  # works
    "[red] wohoo [/red ]" # doesn't
    "[bold blue] wohoo [/bold blue]" # works
    "[bold blue] wohoo [/blue bold]" # doesn't
    ```

!!! tip
    Occasionally you can do without the closing tag:
    
    ```@example
    tprint("[red]text")
    ```
    `Term.jl` will add the closing tag to the end of the string for you. Generally though, when multiple styles are 
    applied to the same string, it's better to be explicit in exactly where each style starts and ends.


## Under the hood

If you're reading here you're curious about what exactly is happening under the hood. So let's get started.
`Term.jl`, like `rich` in python, defines a simple markup language to specify the style of bits of strins.
As we saw, the syntax is very simple with an opening and closing tag specifying the style and marking the start and end of the styled text. 

So the first thing that needs to happen is the **detection** of these markup tags. This is surprisingly hard because there's so many possible combinations. You can have markup tags whose style information varies considerably, you can have nested tags, you can have tags spread across lines and you can have nested tags spread across lines:

```@example
using Term # hide
tprint(
    """
And [blue] somehow
it [bold red] all [/bold red]
has to [green underline] always
work [/green underline] correctly [/blue]
somehow.
    """
)
```

```@meta
CurrentModule = Term.markup
```

All of this is taken care of by `Term.markup.extract_markup` which returns a vector of `Term.markup.MarkupTag` objects. Each of these stores the opening and close tags (as `SingleTag` objects), the text inbetween them as well as a reference to all `MarkupTag`s nested in it.

Normally, you should never use `extract_markup` directly. Instead you can let `Term.style.apply_style` handle it. When passed a `String`, `apply_style` will use `extract_markup` to extract style information before applying it to the string. This is done one `MarkupTag` at the time and recursively (i.e., dealing with nested tags before moving on to the next) until no markup information is found. 

After extracting style information, `apply_style` replaces the `MarkupTag` information with the appropriate [ANSI escape codes](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797). This is done by parsing the markup information (the text bewteen `[...]`) into a `Term.style.MarkupStyle` object which stores the style information. Finally, `get_style_codes` get the ANSI codes corresponding to the required style. 
So in summary:

```julia
apply_style("[red]text[/red]")
```
will return a string with style information

```@example
import Term.style: apply_style  # hide
apply_style("[red]text[/red]") # hide
```

which printed to the console looks like:
```@example
import Term.style: apply_style  # hide
print(apply_style("[red]text[/red]")) # hide
```

