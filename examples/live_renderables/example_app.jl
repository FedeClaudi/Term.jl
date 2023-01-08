"""
This example shows how to create a small app. 

We'll build a "color picker": the use can input three 
numeric values for RGB and the resulting color gets displayed.
A button lets users select a random color. 

The app is made of a "panel" showing the color, three InputBox
to capture the RGB values and a button. 
These are the steps:

1. define layout
2. create widgets
3. create transition rules to shift focus between the widgets
"""

using Term
using Term.LiveWidgets
using Term.Consoles
import Term.LiveWidgets: AbstractWidget, KeyInput, ArrowRight, ArrowLeft, ArrowUp, ArrowDown
import OrderedCollections: OrderedDict
import Term: apply_style
using Term.Compositors

# ------------------------------- app elements ------------------------------- #
# print this compositor if you want to see the layout
layout = :(A(21, 0.4) * (R(6, 0.6) / G(6, 0.6) / B(6, 0.6) / b(3, 0.6)))
template = Compositor(layout)

element_width(elem::Symbol) = template.elements[elem].w
element_height(elem::Symbol) = template.elements[elem].h - 1 # the -1 is to account for focus marker

# create some widgets
rgb_visualizer = TextWidget(""; width = element_width(:A), height = element_height(:A))

R = InputBox(
    width = element_width(:R),
    height = element_height(:R),
    title = "R value",
    style = "red",
    title_justify = :center,
)
G = InputBox(
    width = element_width(:G),
    height = element_height(:G),
    title = "G value",
    style = "green",
    title_justify = :center,
)
B = InputBox(
    width = element_width(:B),
    height = element_height(:B),
    title = "B value",
    style = "blue",
    title_justify = :center,
)

button = Button(
    "random";
    width = element_width(:b),
    height = element_height(:b),
    pressed_background = "light_slate_grey",
    not_pressed_text_style = "light_slate_grey",
)

widgets = OrderedDict{Symbol,AbstractWidget}(
    :A => rgb_visualizer,
    :R => R,
    :G => G,
    :B => B,
    :b => button,
)

# create transition rules
transition_rules = OrderedDict{Tuple{Symbol,KeyInput},Symbol}(
    (:A, ArrowRight()) => :R,
    (:R, ArrowDown()) => :G,
    (:G, ArrowDown()) => :B,
    (:B, ArrowDown()) => :b,
    (:b, ArrowUp()) => :B,
    (:B, ArrowUp()) => :G,
    (:G, ArrowUp()) => :R,
    (:R, ArrowLeft()) => :A,
    (:G, ArrowLeft()) => :A,
    (:B, ArrowLeft()) => :A,
    (:b, ArrowLeft()) => :A,
)

# --------------------------------- functions -------------------------------- #
function get_color(ib::InputBox)
    text = something(ib.input_text, "0")
    text == "" && (text = "0")

    color = try
        parse(Int, text)
    catch
        error("Failed to parse $text as a color")
    end
    return color
end

# define a callback function to update rgb_visalizer at each frame
function update_visualizer(app::App)
    r = get_color(app.widgets[:R])
    g = get_color(app.widgets[:G])
    b = get_color(app.widgets[:B])

    viz = app.widgets[:A]

    viz.text =
        "(r:$r, g:$g, b:$b)" / apply_style(
            join(repeat([" "^(viz.measure.w - 6)], viz.measure.h - 3), "\n"),
            "on_($r, $g, $b)",
        )
end

function set_random_color(::Button)
    app.widgets[:R].input_text = string(rand(0:255))
    app.widgets[:G].input_text = string(rand(0:255))
    app.widgets[:B].input_text = string(rand(0:255))
end

# ------------------------------------ run ----------------------------------- #
# create app and visualize
app = App(layout, widgets, transition_rules; on_draw = update_visualizer)

button.callback = set_random_color

play(app)
