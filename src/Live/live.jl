module LiveWidgets
using REPL.TerminalMenus: readkey, terminal
using REPL.Terminals: raw!, AbstractTerminal
using Dates
import Base.Docs: doc as getdocs
using Markdown
using AbstractTrees

import MyterialColors: pink

import Term: default_width, reshape_text, TERM_THEME, fint
import ..Renderables: AbstractRenderable, RenderableText
import ..Panels: Panel
import ..Measures: Measure
import ..Measures: width as get_width
using ..Consoles
import ..Repr: @with_repr, termshow
import ..Style: apply_style
import ..Layout: Spacer, vLine, vstack, hLine, hstack
import ..Compositors: Compositor, render, update!

export AbstractWidget, refresh!, play, key_press, shouldupdate, frame, stop!
export Pager
export SimpleMenu, ButtonsMenu, MultiSelectMenu
export InputBox, TextWidget, Button, ToggleButton
export Gallery
export App

include("_input.jl")

# ------------------------------- base widgets ------------------------------- #
include("abstract_widget.jl")
include("help.jl")
include("widgets.jl")
include("pager.jl")
include("buttons.jl")
include("menus.jl")

# -------------------------------- containers -------------------------------- #
include("abstract_container.jl")
include("gallery.jl")
include("app.jl")

end
