using Term
using Term.LiveWidgets
install_term_logger()
install_term_stacktrace()

LiveWidgets.LIVE_DEBUG[] = false  # set to true show extra info

"""
Example on how to create a simple app without any specific content, 
just to specify the widget's layout.
"""

layout = :((r(10, 0.5) * g(10, 0.5)) / b(10, 1.0))

app = App(
    layout;
    expand = true,
    help_message = """
This is just an example of how to create a simple app without any specific content.

!!! note
    You can make apps too!
""",
)

play(app)
