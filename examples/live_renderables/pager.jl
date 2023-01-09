import Term: load_code_and_highlight
using Term.LiveWidgets
import Term.Consoles: console_width

"""
Simple example showing how to load a file's content and highlight the syntax to then 
use a pager to view it in the terminal. 

Multiple pagers are visualized via a Gallry widget.
"""

filepath1 = "././src/live/abstract_widget.jl"
filepath2 = "././src/live/gallery.jl"

@assert console_width() > 100 "This example works best in a wide enough temrinal"

gallery = Gallery(
    [
        Pager(
            load_code_and_highlight(filepath1);
            page_lines = 40,
            title = filepath1,
            line_numbers = true,
            width = console_width() - 6,
        ),
        Pager(
            load_code_and_highlight(filepath2);
            page_lines = 40,
            title = filepath2,
            line_numbers = true,
            width = console_width() - 6,
        ),
    ];
    height = 50,
)

LiveWidgets.play(gallery; transient = true)
