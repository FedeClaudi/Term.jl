module Term
# general utils
include("__text_utils.jl")
include("_ansi.jl")
include("_utils.jl")

# don't import other modules
include("measure.jl")
include("color.jl")
include("theme.jl")
include("highlight.jl")

# rely on other modules
include("style.jl")
include("segment.jl")
include("macros.jl")

# renderables, rely heavily on other modules
include("box.jl")
include("console.jl")
include("renderables.jl")
include("layout.jl")
include("panel.jl")
include("errors.jl")
include("tprint.jl")
include("progress.jl")
include("logging.jl")
include("tree.jl")
include("dendogram.jl")
include("logo.jl")
include("inspect.jl")
include("repr.jl")

export RenderableText, Panel, TextBox
export Spacer, vLine, hLine, pad, pad!, vstack, hstack
export theme, highlight
export inspect, typestree, expressiontree
export @red, @black, @green, @yellow, @blue, @magenta, @cyan, @white, @default
export @bold, @dim, @italic, @underline, @style
export tprint, tprintln
export install_stacktrace
export install_term_logger, uninstall_term_logger
export track
export Tree
export Dendogram
export rightalign!, leftalign!, center!, lvstack, cvstack, rvstack, ←, ↓, →, leftalign, center, rightalign
export @with_repr

# ----------------------------------- base ----------------------------------- #
using .measure: measure
using .measure: Measure

# ----------------------------------- style ---------------------------------- #

using .color: NamedColor, BitColor, RGBColor, get_color

using .style: apply_style

using .segment: Segment

"""
    Measure(seg::Segment) 

gives the measure of a segment
"""
measure.Measure(seg::Segment) = seg.measure

"""
    Measure(segments::Vector{Segment})

gives the measure of a vector of segments
"""
function measure.Measure(segments::Vector{Segment})
    return Measure(
        max([seg.measure.w for seg in segments]...),
        sum([seg.measure.h for seg in segments]),
    )
end

# -------------------------------- renderables ------------------------------- #
using .box

using .console: console_height, console_width

using .renderables: AbstractRenderable, Renderable, RenderableText

using .layout: Padding,
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
            ←, ↓, → 


using .panel: Panel, TextBox

# define additional methods for measure functions
measure.width(text::AbstractString) = Measure(text).w
measure.width(seg::Segment) = seg.measure.w
measure.width(ren::AbstractRenderable) = ren.measure.w

measure.height(text::AbstractString) = Measure(text).h
measure.height(seg::Segment) = seg.measure.h
measure.height(ren::AbstractRenderable) = ren.measure.h

# ---------------------------------- others ---------------------------------- #
using .errors: install_stacktrace

using .logging: install_term_logger, uninstall_term_logger, TermLogger

using .Tprint: tprint, tprintln

using .progress: ProgressBar, ProgressJob # update, track

using .tree: Tree

using .dendogram: Dendogram

using .introspection: inspect, typestree, expressiontree

using .Repr: @with_repr

end
