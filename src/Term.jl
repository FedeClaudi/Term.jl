"""
    Term.jl

Welcome to Term.jl! Term.jl is a Julia library for producing styled, beautiful terminal output.

# Documentation

See https://fedeclaudi.github.io/Term.jl for documentation.

# Demonstration

```julia
using Term
const term_demo = joinpath(dirname(pathof(Term)), "..", "README.jl")
include(term_demo) # view demo
less(term_demo) # see demo code
```

# Example

```jldoctest
begin
    println(@green "this is green")
    println(@blue "and this is blue")
    println()
    println(@bold "this is bold")
    println(@underline "and this is underlined")
end
```
"""
module Term

using Unicode

const DEBUG_ON = Ref(false)

const ACTIVE_CONSOLE_WIDTH = Ref{Union{Nothing,Int}}(nothing)
const ACTIVE_CONSOLE_HEIGHT = Ref{Union{Nothing,Int}}(nothing)

default_width(io = stdout) = min(88, something(ACTIVE_CONSOLE_WIDTH[], displaysize(io)[2]))
default_stacktrace_width(io = stderr) =
    min(140, something(ACTIVE_CONSOLE_WIDTH[], displaysize(io)[2]))

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
include("tables.jl")
include("markdown.jl")
include("repr.jl")
include("compositors.jl")
include("grid.jl")
include("introspection.jl")

export RenderableText, Panel, TextBox, @nested_panels
export TERM_THEME, highlight
export @red, @black, @green, @yellow, @blue, @magenta, @cyan, @white, @default
export @bold, @dim, @italic, @underline, @style
export tprint, tprintln
export install_term_stacktrace,
    install_term_logger, uninstall_term_logger, install_term_repr
export vLine, hLine
export @with_repr, termshow, @showme
export Compositor, update!
export grid
export inspect

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

using .Panels: Panel, TextBox, @nested_panels

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
    Measure(segments::AbstractVector)

gives the measure of a vector of segments
"""
Measures.Measure(segments::AbstractVector) =
    if length(segments) == 0
        Measure(0, 0)  # nothing we can do here
    else
        Measure(sum(Measures.height.(segments)), maximum(Measures.width.(segments)))
    end

# ---------------------------------- others ---------------------------------- #
using .Errors: install_term_stacktrace

using .Logs: install_term_logger, uninstall_term_logger, TermLogger

using .Tprint: tprint, tprintln

using .Progress: ProgressBar, ProgressJob, with, @track

using .Trees: Tree

using .Dendograms: Dendogram

using .Introspection: inspect, typestree, expressiontree, inspect

using .Tables: Table

using .Compositors: Compositor, update!

using .TermMarkdown: parse_md

using .Repr: @with_repr, termshow, install_term_repr, @showme

using .Grid

end
