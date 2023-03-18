# Widgets

Widgets are the building blocks that `App`s are made of. 
A widget is generally a single piece of content with a specific function (display text, act as a button...).

## Predefined widgets
`Term` comes with a bunch of widgets you can already plug into your applications.
If you want to develop your own, read below. 

### TextWidget
We've seen this already, it's the simplest widget: just show some text. 


```@example widgets
using Term.LiveWidgets

TextWidget("Hello world!") |> frame

```

unlike other widgets it doesn't have a whole lot of options, just gives you the 
choice of showing just text or a panel:
```@example widgets
TextWidget("Hello world!", as_panel=true) |> frame
```

### InputBox
This widget is a bit more complex. It's a text input box. It's a bit like a `TextWidget` but it also allows the user to type in it.
When this widget is active, any key press get's captured and displayed as text in the widget. 
As usual things like Space Bar, Enter and Del add spaces, new lines and delete characters respectively. 
Make an `App` with an `InputBox` to see how it works!

### Buttons
```@example widgets
Button("Click me please!") |> frame
```
You can specify the color of the text and the button. You can also pass a `callback`: a `Function` that gets called 
when the button is pressed. 

Normally, when pressed, a button will change its color to indicate that it has been pressed and then revert to its
original style. If you want something that acts like a toggle switch, use `ToggleButton` instead. 



### Menus

The idea is simple, provide the user with some option and let them choose one. 
```@example widgets
SimpleMenu(["Option 1", "Option 2", "Option 3"]) |> frame
```

the user can use the arrow keys to navigate the menu and press Enter to select an option.
Selecting an options quits the application and returns an integer with the index of the selected option.
`active_style, inactive_style` can be used to set the style of the currently active options while the user 
navigates the menu. The `layout` options lets you choose if you want the options to be displayed horizontally or vertically.
If you want the menu elements to stand out more, you can use `ButtonsMenu`. 


If you want to let users select more than one option at once, use `MultiSelectMenu`. It shows a checkbox like display and 
users can use the space bar to toggle the state of the checkbox.

### Pager
A pager is a widget that lets you display a lot of text in a scrollable window. 
```@example widgets
Pager("This is a pager. It lets you display a lot of text in a scrollable window."^300) |> frame
```

You can use various keyboard inputs to navigate the pager (arrows to move up and down and to page up and down, Home and End to go to the top and bottom of the text respectively).

You can specify the size (height and width) of the pager and if line numbers should be shown (useful to display code):

```@example widgets
Pager("This is a pager. It lets you display a lot of text in a scrollable window."^300, height=20, width=20, line_numbers=true) |> frame
```


### Gallery

A `Gallery` is somewhat in between a widget and an `App`. It's a container for other widgets. 
Only one widget at the time is displayed in the space taken by the `Gallery`.

```@example widgets
g = Gallery(
    [TextWidget("Hello world!"), TextWidget("Not shown")];
    height = 25, width=60, title="My gallery"
) |> frame
```

Use arrows to change which widget is active. 


## Defining widgets
All widgets are subtypes of the `abstract type AbstractWidget`.
A new widget type needs to be defined as a `mutable struct` and it needs to have two obligatory fields:
```julia
    internals::WidgetInternals
    controls::AbstractDict
```

`WidgetInternals` is a struct that contains the state of the widget. It keeps track of things like the size 
of the widget and the three callback functions `on_draw`, `on_activated` and `on_deactivated`. 
These are optional functions that are called when `frame` is called on a widget or when the widget is activated or deactivated.
The activated/deactivated functions can be used to change the appearance of the widget to signal to the user that the widget is active or not.

`controls` is a `Dict{Union{Char, KeyboardInput}, Function}` that says how keyboard inputs should be used: it maps a keyboard input to a function that gets called when that input is pressed if the widget is active. 

Other than these obligatory fields, the `struct` needs to have anything that the widget needs to work.

Two obligatory methods need to be defined for the widget to work. 
`frame(w::MyWidget; kwargs...)::AbstractRenderbles`  is the function that gets called when the app's display is updated. The renderable that is returned is what gets displayed on the screen.
`on_layout_change(w::MyWidget, m::Measure)` says what should happen when the app gets resized. The `Measure` is the new size of the widget.
Usually it's enough to do something like:
```julia
on_layout_change(t::TextWidget, m::Measure) = t.internals.measure = m
```


To get an idea of how to define a widget, take a look at the source code of the widgets that come with `Term`.