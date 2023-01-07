using Term
using Term.LiveWidgets
using Term.Consoles
using Term.Progress
import Term: load_code_and_highlight
using Term.Compositors

import Term.LiveWidgets: AbstractWidget, KeyInput, ArrowRight, ArrowLeft, ArrowUp, ArrowDown


filepath = "././src/live/abstract_widget.jl"
code = load_code_and_highlight(filepath)
text = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque varius metus vitae sapien sollicitudin, eu commodo urna pulvinar. Nunc commodo sed lectus vel volutpat. Fusce ornare fringilla nisi, vitae varius ante malesuada sit amet. Etiam dignissim urna vel lorem laoreet sodales. Sed sollicitudin, lorem a posuere luctus, purus orci maximus urna, in placerat tortor est nec odio. Fusce vulputate laoreet sagittis. Mauris quis pretium mi. Nunc leo ex, tincidunt nec nisl nec, condimentum tincidunt mi. Nulla facilisi. Sed congue nibh nec eros mollis convallis.

Quisque maximus purus ex, id congue ante egestas nec. Phasellus id finibus augue, eget pellentesque leo. Aliquam sollicitudin consectetur nisi, sed lacinia neque rutrum id. Nullam ultricies purus massa, et pharetra nunc euismod vitae. Duis convallis diam tellus. Aliquam interdum pellentesque eros eu tristique. Integer feugiat quis sem ut varius. Ut ac enim pharetra, consectetur ligula in, tincidunt lorem. Pellentesque mattis imperdiet justo, nec pretium odio placerat ut. Proin dignissim sollicitudin massa, vel vestibulum metus maximus eu. Fusce gravida, odio gravida egestas accumsan, metus quam sollicitudin arcu, eu gravida felis quam nec metus. Nunc non erat massa. Ut ullamcorper pellentesque sem, nec vulputate metus tristique vel. Lorem ipsum dolor sit amet, consectetur adipiscing elit.

Curabitur mattis malesuada sapien, eget faucibus risus. Suspendisse mattis, velit id vehicula pretium, tortor odio fermentum magna, id fringilla est tellus id tellus. Nam mattis sem urna, id volutpat lacus maximus eu. Nullam a orci eu quam accumsan rhoncus molestie a dolor. Morbi faucibus hendrerit quam, sodales ullamcorper nunc. Vivamus aliquet quam leo, sit amet gravida nisl cursus vitae. Nulla justo justo, varius non dignissim nec, egestas non erat. Quisque interdum magna id eros efficitur mollis. Maecenas tincidunt risus at nisl aliquam suscipit. Mauris odio dolor, consectetur a rutrum ac, gravida id ligula. Nulla ac sapien erat. Morbi aliquet arcu sed eros semper sollicitudin. 
"""


layout = :(
    (A(20, $(0.6)) * B(20, $(0.4)))/
    (C(5, 0.8) * D(5, 0.2))
    
    )
compositor = Compositor(layout)
# print(compositor)


widgets = Dict{Symbol, AbstractWidget}(
    :A => TextWidget(text; width=compositor.elements[:A].w, height=compositor.elements[:A].h-1, as_panel=true),
    :B => Pager(text; width=compositor.elements[:B].w, page_lines=compositor.elements[:B].h-5),
    :C => InputBox(; width=compositor.elements[:C].w, height=compositor.elements[:C].h-1),
    :D => Button("launch"; width=compositor.elements[:D].w, height=compositor.elements[:D].h-1),
)


transition_rules = Dict{Tuple{Symbol, KeyInput},Symbol}(
    (:A, ArrowRight()) => :B,
    (:A, ArrowDown()) => :C,
    
    (:B, ArrowLeft()) => :A,
    (:B, ArrowDown()) => :C,

    (:C, ArrowUp()) => :A,
    (:C, ArrowRight()) => :D,
    
    (:D, ArrowUp()) => :A,
    (:D, ArrowLeft()) => :C,
)

app = App(layout, widgets, transition_rules)


play(app)

# TODO inspect make useof gallery and app