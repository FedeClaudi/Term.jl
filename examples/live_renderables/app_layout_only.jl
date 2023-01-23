using Term
using Term.LiveWidgets
install_term_logger()

LiveWidgets.LIVE_DEBUG[] = false  # set to true show extra info

"""
Example on how to create a simple app without any specific content, 
just to specify the widget's layout.
"""

layout = :(
    (r(10, 0.5)* g(10, 0.5))/ b(10, 1.0)
)

app = App(
    layout;
    expand = true,
)

play(app)


