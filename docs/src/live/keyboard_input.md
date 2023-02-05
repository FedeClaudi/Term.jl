# Keyboard input
Apps can capture input from the user by reading key presses and passing them to the active widget. 

Each widget must have a `controls` attribute with a dictionary mapping keys to function. 
The keys of this dictionary can take one of two types: 
- `Char`: a single character. Used to map a "letter" key to a function. For example `q` generally quits the app and `h` displays help.
- a `KeyInput` type like `ArrowLeft()` or `HomeKey()`. These are special keys including the arrows, page up/down, Esc, Del and SpaceBar. 


The values of the dictionary are functions. The function should have a signature: `fn(w, k)` where `w` is the widget they are assigned to and `k` is the key that was pressed.
For example in `Pager` you can use `ArrowRight, PageDownKey` and `]` to scroll down so a function is defined as:
```julia
next_page(p::Pager, ::Union{PageDownKey,ArrowRight,Char})
```

and with similar functions the `controls` for `Pager` are:
```

pager_controls = Dict(
    ArrowRight() => next_page,
    ']' => next_page,
    ArrowLeft() => prev_page,
    '[' => prev_page,
    ArrowDown() => next_line,
    '.' => next_line,
    ArrowUp() => prev_line,
    ',' => prev_line,
    HomeKey() => home,
    EndKey() => toend,
    Esc() => quit,
    'q' => quit,
)
```

there's no restriction to which/how many control functions you should have and how they should affect your widget.
However having `quit` is generally a good idea or the user can't quit the app while that widget is active!
Different widgets will have different controls. 
A widget's controls are only activated if the corresponding key is pressed while the widget is active.