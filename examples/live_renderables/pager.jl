import Term: load_code_and_highlight
using Term.LiveDisplays

"""
Simple example showing how to load a file's content and highlight the syntax to then 
use a pager to view it in the terminal. 

Press "h" for a help menu, "q" to quit.
"""

filepath = "././src/live/abstractlive.jl"
code = load_code_and_highlight(filepath)


p = Pager(code; page_lines = 20, title = filepath) |> LiveDisplays.play


# TODO for help: 2) get docstrings of key_press functions and print that.
