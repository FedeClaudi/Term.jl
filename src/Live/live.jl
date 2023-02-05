module LiveWidgets
using REPL.TerminalMenus: readkey, terminal
using REPL.Terminals: raw!, AbstractTerminal
using Dates
import Base.Docs: doc as getdocs
using Markdown
using AbstractTrees
import MyterialColors: Palette, blue, pink

import MyterialColors: pink

import Term: default_width, reshape_text, TERM_THEME, fint, reshape_code_string, remove_ansi
import ..Renderables: AbstractRenderable, RenderableText
import ..Panels: Panel
import ..Measures: Measure
import ..Measures: width as get_width
import ..Measures: height as get_height
using ..Consoles
import ..Repr: @with_repr, termshow
import ..Style: apply_style
import ..Layout: Spacer, vLine, vstack, hLine, hstack, PlaceHolder
import ..Compositors: Compositor, render, update!
import ..Tprint: tprint
import ..TermMarkdown: parse_md

export AbstractWidget, refresh!, play, key_press, shouldupdate, frame, stop!
export Pager
export SimpleMenu, ButtonsMenu, MultiSelectMenu
export InputBox, TextWidget, Button, ToggleButton
export Gallery
export App
export ArrowDown,
    ArrowUp,
    ArrowLeft,
    ArrowRight,
    DelKey,
    HomeKey,
    EndKey,
    PageUpKey,
    PageDownKey,
    Enter,
    SpaceBar,
    Esc,
    Del

const LIVE_DEBUG = Ref(false)

# ----------------------------- keyboard controls ---------------------------- #
abstract type KeyInput end

struct ArrowLeft <: KeyInput end
struct ArrowRight <: KeyInput end
struct ArrowUp <: KeyInput end
struct ArrowDown <: KeyInput end
struct DelKey <: KeyInput end
struct HomeKey <: KeyInput end
struct EndKey <: KeyInput end
struct PageUpKey <: KeyInput end
struct PageDownKey <: KeyInput end
struct Enter <: KeyInput end
struct SpaceBar <: KeyInput end
struct Esc <: KeyInput end
struct Del <: KeyInput end

KEYs = Dict{Int,KeyInput}(
    13 => Enter(),
    27 => Esc(),
    32 => SpaceBar(),
    127 => Del(),
    1000 => ArrowLeft(),
    1001 => ArrowRight(),
    1002 => ArrowUp(),
    1003 => ArrowDown(),
    1004 => DelKey(),
    1005 => HomeKey(),
    1006 => EndKey(),
    1007 => PageUpKey(),
    1008 => PageDownKey(),
)

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

include("keyboard_input.jl")

end
