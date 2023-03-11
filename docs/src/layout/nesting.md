# Nesting

The simplest way to create a layout with multiple elements: put one into the other.
We've already seen how you can do it with `Panel`s:

```@example nesting

import Term: Panel # hide


Panel(
    Panel(
        Panel(
            "We need to go deeper...",
            height=3,
            width=28,
            style="green",
            box=:ASCII,
            title="ED",title_style="white",
            justify=:center
        ),
        style="red", box=:HEAVY, title="ST", title_style="white", fit=true
    ),
    width=44, justify=:center, style="blue", box=:DOUBLE, title="NE", title_style="white"
)

```


okay, nothing crazy here - but we can actually achieve some nice looking layouts with this alone:

```@example nesting
import Term: Panel, TextBox

title = Panel(
    "{white bold}This is an {red} important {/red}title{/white bold}";
    width=60, fit=false, box=:DOUBLE_EDGE, style="bright_blue dim", justify=:center
)
summary = Panel(
    "This is a short summary of the content of the next paragraph."^5;
    width=60, fit=false, style="dim", justify=:left,
    padding=(4, 4, 1, 1), title="Summary", title_style="white default"
)

main_text = TextBox(
    "This is a very long paragraph with a lot of text you don't need to read."^10;
    width=60, fit=false, style="bright_blue dim", justify=:left
)

Panel(title, summary, main_text; style="#9bb3e0", subtitle="Technical details", 
subtitle_justify=:right, subtitle_style="yellow default"
)
```

## Nested layouts? No head ache
If you want to have several nested panels, you might want to make sure that their widths are set correctly so that they fit nicely together. There's a macro for that!

```@example nesting
import Term: @nested_panels
@nested_panels Panel(
    Panel(
        Panel(
            Panel(
                ; title="deepest", style="blue", background="blue"
            ); title="deeper", style="green");
        title="not so deep");
    style="red",
    title="outer"
) 
```
It sets the width of each panel to match their depth. It only works if you're actively calling Panel() in the macro call.
something like this won't work:
```@example nesting
another_panel = Panel("this won't work")
@nested_panels Panel(
    Panel(
        Panel(
            Panel(
                another_panel,
                ; title="deepest", 
            ); title="deeper", style="green");
        title="not so deep");
    style="red",
    title="outer"
) 

```


This is all nice, but, that's not enough... so let' see what more we can do!


