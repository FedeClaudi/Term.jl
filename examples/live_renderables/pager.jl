import Term: load_code_and_highlight
using Term.LiveWidgets
import Term.Consoles: console_width

"""
Simple example showing how to load a file's content and highlight the syntax to then 
use a pager to view it in the terminal. 

Multiple pagers are visualized via a Gallry widget.
"""

import Term.LiveWidgets: LIVE_DEBUG
LIVE_DEBUG[] = false

filepath1 = "././src/live/abstract_widget.jl"
filepath2 = "././src/live/gallery.jl"

gallery = Gallery(
    [
        Pager(
            load_code_and_highlight(filepath1);
            height = 40,
            title = filepath1,
            line_numbers = true,
            width = console_width() - 6,
        ),
        Pager(
            load_code_and_highlight(filepath2);
            height = 40,
            title = filepath2,
            line_numbers = true,
            width = console_width() - 6,
        ),
    ];
    height = 50,
)

app = App(gallery)
play(app; transient = true)

#TODO pager update tot lines, line number...
