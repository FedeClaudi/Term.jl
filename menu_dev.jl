using Term
using Term.LiveDisplays
using Term.Consoles
using Term.Progress
import Term: load_code_and_highlight

# clear() 



txt = "Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit,\nsed do eiusmod tempor incididunt ut labore"^100


options = ["one", "two"]
tabs = [
    Pager(txt; page_lines = 40, title = "", line_numbers=true, width=console_width()-20),
    Pager(txt; page_lines = 40, title = "", line_numbers=true, width=console_width()-20),
]

tb = TabViewer(options, tabs)
LiveDisplays.play(tb)


#TODO fix problems with key_press(live::TabViewer, k::CharKey)