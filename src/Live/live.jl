module LiveDisplays
using REPL.TerminalMenus: readkey, terminal
using REPL.Terminals: raw!, AbstractTerminal
using Dates
Base.start_reading(stdin)

import MyterialColors: pink

import Term: default_width
import ..Renderables: AbstractRenderable, RenderableText
import ..Panels: Panel
import ..Measures: Measure
using ..Consoles
import ..Repr: @with_repr, termshow

export AbstractLiveDisplay, refresh!, play, key_press, shouldupdate, frame, stop!
export Pager, TabViewer, TextTab, PagerTab

include("abstractlive.jl")
include("input.jl")
include("pager.jl")
include("tabviewer.jl")

end
