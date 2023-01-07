import Term: load_code_and_highlight
using Term.LiveWidgets

"""
Simple example showing how to load a file's content and highlight the syntax to then 
use a pager to view it in the terminal. 

Press "h" for a help menu, "q" to quit.
"""

filepath = "././src/live/abstract_widget.jl"
code = load_code_and_highlight(filepath)


LiveWidgets.play(Pager(code; page_lines = 40, title = filepath, line_numbers=true); transient=true)
