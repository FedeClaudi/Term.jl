module LiveDisplays
using REPL.TerminalMenus: readkey, terminal
using REPL.Terminals: raw!, AbstractTerminal
using Dates
import Base.Docs: doc as getdocs
using Markdown
Base.start_reading(stdin)

import MyterialColors: pink

import Term: default_width
import ..Renderables: AbstractRenderable, RenderableText
import ..Panels: Panel
import ..Measures: Measure
import ..Measures: width as get_width
using ..Consoles
import ..Repr: @with_repr, termshow
import ..Style: apply_style

export AbstractLiveDisplay, refresh!, play, key_press, shouldupdate, frame, stop!
export Pager, TabViewer, TextTab, PagerTab
export SimpleMenu, ButtonsMenu, MultiSelectMenu

include("input.jl")
include("abstractlive.jl")
include("pager.jl")
include("menu.jl")
include("tabviewer.jl")

end
