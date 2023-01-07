using Term
using Term.LiveWidgets
using Term.Consoles
using Term.Progress
import Term: load_code_and_highlight
using Term.Compositors


layout = :(A(20, $(0.75)) * B(20, $(0.25)))
Compositor(layout)
