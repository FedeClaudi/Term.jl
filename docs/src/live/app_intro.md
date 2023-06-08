# App

The starting point of any good "live" or interactive terminal display is an `App`. The `App` takes care of generating and updating the visuals as well as taking in user input making use of it (e.g. to update the display accordingly). 
An app has some content. This content is in the form of `AbstractWidget` elements. These widgets are single content elements that serve a specific function, for example displaying some text or acting as buttons etc. More on widgets later. In addition to knowing **what** is in an app, we also need to specify **how** it should look like. Specifically, how should the different widgets be layed out.  So in addition to creating widgets, you will need to specify a layout for your app. 
There's a lot more to apps, but for now we can start with some simple examples

### A first example
We start with a simple example: an app that only shows one single widget. a `TextWidget` displaying a bit of text. As the output is quite long, we supress the it to avoid cluttering this page. Note that Term 2.0 is required to create live widgets.

```@example app
using Term
using Term.LiveWidgets

app = App(
    TextWidget("""
The starting point of any good "live" or interactive terminal display is an `App`. The `App` takes care of generating and updating the visuals as well as taking in user input making use of it (e.g. to update the display accordingly). 
An app has some content. This content is in the form of `AbstractWidget` elements. These widgets are single content elements that serve a specific function, for example displaying some text or acting as buttons etc. More on widgets later. In addition to knowing **what** is in an app, we also need to specify **how** it should look like. Specifically, how should the different widgets be layed out.  So in addition to creating widgets, you will need to specify a layout for your app. 
There's a lot more to apps, but for now we can start with some simple examples
""")
);

```

Easy. Now to *use* the app you'd call `play(app)`. This starts an interactive session in which the app continuously refreshes its display and reacts to user input until the app is exited by pressing `q` or `Esc`.
Unfortunately we can't do that here in the docs, but we can use `frame` to see what the app would look like
when we start it:

```@example app
frame(app)
```

!!! tip "Ask for help"
    Press `h` while using `play` to interact with an app to display a help tooltip.

### Layout
Ok, one widget apps are not that useful. 
When adding more widgets you'll eventually have to specify how to lay them out. Essentially you want to specify the space taken by the app as a whole  (the width and height in the terminal) and then within that you need to specify the size of each 
widgets and where they are located (e.g. widget A is to the left of B and A,B together are above C).

To specify the layout you need to use an `Expr` like the one used for ['Compositor'](@ref CompositorDocs) content. 
The expression is made of elements like `a(h, w)` where `a` is the layout element's name and `h,w` are the height and width of the element.
Note that `h` has to be an integer (the number of lines spanned by the widget) but `w` can be either `Int` (number of columns) or `Float64` with `0 < w < 1` to specify the fraction of the available space that should be used.

For example:
```julia
:r(10, 0.5)
```
says that the widget `r` should take up 10 lines and half of the available width.

In addition to elements, you can use `*` and `/` to specify the relation between elements: `*` means "to the side of" and `/` means "above".
Combined with parentheses you can get some pretty complex layouts. For example:

```@example app
layout = :(
    :(( a(10, .5) * b(10, .5) )/c(10, 1))
)
```

With a layout in mind you can start creating your app.
Eventually you'll need to provide some widgets too, but if you just want to check the layout (and maybe tweak it) you can 
create an empty app with placeholders to visualize the position of each widget:

```@example app
App(layout) |> frame  
```

Note that you can always specify the `width` and `height` of the app. If you don't, the app will try to use the full terminal size.


!!! tip "Responsive layout"
    If you use a `Float` to specify your layout elements size, the app will automatically resize the elements when the terminal 
    size is reduced. If you also want your app to expand to fill in the whole terminal if the terminal is enlarged, you can use
    `expand` keyword argument for `App`. 



### Adding widgets
To create an app with multiple widgets, you'll need the layout info as shown above and a `Dict` with 
the widgets you want your app to display. The keys in the `Dict` need to match the layout elements names.
For example, to create an app showing two pieces of text.

```@example app

layout = :(a(25, .5) * b(25, .5))

widgets = Dict(
    :a => TextWidget("""To create an app with multiple widgets, you'll need the layout info as shown above and a `Dict` with 
the widgets you want your app to display. The keys in the `Dict` need to match the layout elements names.
For example, to create an app showing two pieces of text.
"""; as_panel=true),
    :b => TextWidget("""
    The starting point of any good "live" or interactive terminal display is an `App`. The `App` takes care of generating and updating the visuals as well as taking in user input making use of it (e.g. to update the display accordingly). 
An app has some content. This content is in the form of `AbstractWidget` elements. These widgets are single content elements that serve a specific function, for example displaying some text or acting as buttons etc. More on widgets later. In addition to knowing **what** is in an app, we also need to specify **how** it should look like. Specifically, how should the different widgets be layed out.  So in addition to creating widgets, you will need to specify a layout for your app. 
There's a lot more to apps, but for now we can start with some simple examples
"""; as_panel=true)
)

App(layout; widgets=widgets) |> frame
```

Note that one panel is dim while the other is not, why?
That's because the app considers the first widget to be 'active' and the brighter color signals that. 
Different widgets show that they are active differently, but generally they use colors to signal to the user that they are 
the currently active one. This is important because user input's (like key presses) will be passed to the currently active widget.
For example, if you have a widget that is a button and it get's pressed by using `spacebar`, then pressing space
will only work if the button is active.

To change the currently active widget you can "navigate" through the app using arrow keys. 
`App` analyzes the `layout` of the app to infer the relative position of the widgets and set up the navigation accordingly.
To test this, use `play` on the app we just created and then left/right arrow to change focus!
(Don't forget to use `q` to exit the app when you're done)

### Activating widgets by keyboard input
Sometimes you want different ways to specify which widget should be active, either by using an arrow key or by pressing a specific key. While there are some defaults for simple apps, you will likely need to specify these "transition rules" manually for most layouts. This is done by passing a `Dict` as the keyword argument `transition_rules` when you create your `App`.  The keys of `transition_rules` should be of type `KeyInput`, and the values should of type `Dict`, mapping symbols to symbols. The wording can get complicated with these nested dictionaries, so the example below hopefully explains how to define apropriate transition rules:
```
App(
    # Layout: 3 columns (a b c), with b split in the middle
    :(a(10, 0.2) * (b1(5, 0.2) / b2(5, 0.2)) * c(10, 0.2)); 
    widgets = Dict(
        :a => TextWidget("Box 1", as_panel=true),
        :b1 => TextWidget("Box 2.1", as_panel=true),
        :b2 => TextWidget("Box 2.2", as_panel=true),
        :c => TextWidget("Box 3", as_panel=true),
    ), transition_rules = Dict(
        ArrowRight() => Dict(:a => :b1, :b1=>:c, :b2=>:c),
        ArrowLeft() => Dict(:c => :b1, :b1=>:a, :b2=>:a),
        ArrowDown() => Dict(:b1 => :b2),
        ArrowUp() => Dict(:b2 => :b1),
    )
)
```
To mentally parse the first transition rule, you should think "When ArrowRight is pressed, if :a is selected, move to :b1. If :b1 is selected, move to :c. If :b2 is selected, move to :c."
