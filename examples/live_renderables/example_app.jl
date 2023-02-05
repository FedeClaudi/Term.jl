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
import Term.LiveWidgets:
    AbstractWidget, KeyInput, ArrowRight, ArrowLeft, ArrowUp, ArrowDown, set_active
import OrderedCollections: OrderedDict
import Term: apply_style
using Term.Compositors

# ------------------------------- app elements ------------------------------- #
# create some widgets
rgb_visualizer = TextWidget("")

R = InputBox(title = "R value", style = "red", title_justify = :center)
G = InputBox(title = "G value", style = "green", title_justify = :center)
B = InputBox(title = "B value", style = "blue", title_justify = :center)

button = Button("random"; color = "light_slate_grey", text_color = "white")

widgets = OrderedDict{Symbol,AbstractWidget}(
    :A => rgb_visualizer,
    :R => R,
    :G => G,
    :B => B,
    :b => button,
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
            join(
                repeat([" "^(viz.internals.measure.w - 4)], viz.internals.measure.h),
                "\n",
            ),
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
layout = :(A(22, 0.4) * (R(6, 0.6) / G(6, 0.6) / B(6, 0.6) / b(4, 0.6)))
app = App(layout; widgets = widgets, on_draw = update_visualizer)

button.callback = set_random_color

play(app);

# TODO on highlight stuff

nothing
