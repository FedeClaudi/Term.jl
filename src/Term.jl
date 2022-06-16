module Term

const DEBUG_ON = Ref(false)
const DEFAULT_WIDTH = Ref(88)  # default width
const DEFAULT_ASPECT_RATIO = Ref(4 / 3)  # 4:3 - 16:9 - 21:9

# general utils
include("__text_utils.jl")
include("_ansi.jl")
include("_utils.jl")
include("_text_reshape.jl")

# don't import other modules
include("measures.jl")
include("colors.jl")
include("theme.jl")
include("highlight.jl")

const TERM_THEME = Ref(Theme())

function update! end

# rely on other modules
include("style.jl")
include("segments.jl")
include("macros.jl")

# renderables, rely heavily on other modules
include("boxes.jl")
include("console.jl")
include("renderables.jl")
include("layout.jl")
include("panels.jl")
include("errors.jl")
include("tprint.jl")
include("progress.jl")
include("logs.jl")
include("trees.jl")
include("dendograms.jl")
include("introspection.jl")
include("tables.jl")
include("markdown.jl")
include("repr.jl")
include("compositors.jl")
include("grid.jl")

export RenderableText, Panel, TextBox
export TERM_THEME, highlight
export @red, @black, @green, @yellow, @blue, @magenta, @cyan, @white, @default
export @bold, @dim, @italic, @underline, @style
export tprint, tprintln
export install_term_stacktrace,
    install_term_logger, uninstall_term_logger, install_term_repr
export vLine, hLine
export @with_repr, termshow
export Compositor, update!
export grid

# ----------------------------------- base ----------------------------------- #
using .Measures

# ----------------------------------- style ---------------------------------- #

using .Colors: NamedColor, BitColor, RGBColor, get_color

using .Style: apply_style

using .Segments: Segment

# -------------------------------- renderables ------------------------------- #
using .Boxes

using .Consoles: console_height, console_width

using .Renderables: AbstractRenderable, Renderable, RenderableText

using .Layout

using .Panels: Panel, TextBox

# define additional methods for measure functions

Measures.width(seg::Segment) = seg.measure.w
Measures.width(ren::AbstractRenderable) = ren.measure.w

Measures.height(seg::Segment) = seg.measure.h
Measures.height(ren::AbstractRenderable) = ren.measure.h

"""
    Measure(seg::Segment) 

gives the measure of a segment
"""
Measures.Measure(seg::Segment) = seg.measure

"""
    Measure(segments::Vector{Segment})

gives the measure of a vector of segments
"""
Measures.Measure(segments::Vector{Segment}) =
    Measure(sum(Measures.height.(segments)), maximum(Measures.width.(segments)))

# ---------------------------------- others ---------------------------------- #
using .Errors: install_term_stacktrace

using .Logs: install_term_logger, uninstall_term_logger, TermLogger

using .Tprint: tprint, tprintln

using .Progress: ProgressBar, ProgressJob, with, @track

using .Trees: Tree

using .Dendograms: Dendogram

using .Introspection: inspect, typestree, expressiontree

using .Tables: Table

using .Compositors: Compositor, update!

using .TermMarkdown: parse_md

using .Repr: @with_repr, termshow, install_term_repr

using .Grid

end
