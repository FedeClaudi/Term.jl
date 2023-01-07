using Term
using Term.LiveWidgets
using Term.Consoles
using Term.Progress
import Term: load_code_and_highlight
using Term.Compositors

import Term.LiveWidgets: AbstractWidget, KeyInput, ArrowRight, ArrowLeft


filepath = "././src/live/abstract_widget.jl"
code = load_code_and_highlight(filepath)
text = "adk ahfb fuhbf auhfba wfhbwsfewhabf ahjbef auhjbf awihbf \n"^50


layout = :(A(20, $(0.75)) * B(20, $(0.25)))
compositor = Compositor(layout)


widgets = Dict{Symbol, AbstractWidget}(
    :A => Pager(text; width=compositor.elements[:A].w),
    :B => Pager(text; width=compositor.elements[:B].w),
)


transition_rules = Dict{Tuple{Symbol, KeyInput},Symbol}(
    (:A, ArrowRight()) => :B,
    (:B, ArrowLeft()) => :A,

)

app = App(layout, widgets, transition_rules)


play(app)


