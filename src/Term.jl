module Term

# general utils
include("__text_utils.jl")
include("_ansi.jl")
include("_utils.jl")

# don't import other modules
include("measures.jl")
include("colors.jl")
include("theme.jl")
include("highlight.jl")

const TERM_DEBUG_ON = Ref(true)
const term_theme = Ref(Theme())

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
include("logo.jl")
include("introspection.jl")
include("tables.jl")
include("repr.jl")
include("compositor.jl")

export RenderableText, Panel, TextBox
export Spacer, vLine, hLine, pad, pad!, vstack, hstack
export term_theme, highlight
export inspect, typestree, expressiontree
export @red, @black, @green, @yellow, @blue, @magenta, @cyan, @white, @default
export @bold, @dim, @italic, @underline, @style
export tprint, tprintln
export install_term_stacktrace
export install_term_logger, uninstall_term_logger
export track
export Tree
export Dendogram
export rightalign!,
    leftalign!,
    center!,
    lvstack,
    cvstack,
    rvstack,
    leftalign,
    center,
    rightalign,
    vertical_pad!,
    vertical_pad
export @with_repr, termshow, install_term_repr, PlaceHolder

# ----------------------------------- base ----------------------------------- #
using .Measures

# ----------------------------------- style ---------------------------------- #

using .Colors: NamedColor, BitColor, RGBColor, get_color

using .Style: apply_style

using .Segments: Segment

"""
    Measure(seg::Segment) 

gives the measure of a segment
"""
Measures.Measure(seg::Segment) = seg.measure

"""
    Measure(segments::Vector{Segment})

gives the measure of a vector of segments
"""
function Measures.Measure(segments::Vector{Segment})
    return Measure(
        max([seg.measure.w for seg in segments]...),
        sum([seg.measure.h for seg in segments]),
    )
end

# -------------------------------- renderables ------------------------------- #
using .Boxes

using .Consoles: console_height, console_width

using .Renderables: AbstractRenderable, Renderable, RenderableText

using .Layout:
    Padding,
    vstack,
    hstack,
    Spacer,
    vLine,
    hLine,
    pad,
    pad!,
    rightalign!,
    leftalign!,
    center!,
    leftalign,
    center,
    rightalign,
    lvstack,
    cvstack,
    rvstack,
    PlaceHolder,
    vertical_pad!,
    vertical_pad

using .Panels: Panel, TextBox

# define additional methods for measure functions
Measures.width(seg::Segment) = seg.measure.w
Measures.width(ren::AbstractRenderable) = ren.measure.w

Measures.height(seg::Segment) = seg.measure.h
Measures.height(ren::AbstractRenderable) = ren.measure.h

# ---------------------------------- others ---------------------------------- #
using .Errors: install_term_stacktrace

using .Logs: install_term_logger, uninstall_term_logger, TermLogger

using .Tprint: tprint, tprintln

using .Progress: ProgressBar, ProgressJob # update, track

using .Trees: Tree

using .Dendograms: Dendogram

using .Introspection: inspect, typestree, expressiontree

using .Repr: @with_repr, termshow, install_term_repr

using .Tables: Table

using .Compositors: Compositor

end
