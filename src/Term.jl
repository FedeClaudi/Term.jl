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

``` julia
``` julia
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

const STACKTRACE_HIDDEN_MODULES = Ref(String[])
const STACKTRACE_HIDE_FRAMES = Ref(true)

const DEBUG_ON = Ref(false)

const ACTIVE_CONSOLE_WIDTH = Ref{Union{Nothing,Int}}(nothing)
const ACTIVE_CONSOLE_HEIGHT = Ref{Union{Nothing,Int}}(nothing)
const DEFAULT_CONSOLE_WIDTH = Ref{Int}(88)
const DEFAULT_STACKTRACE_WIDTH = Ref{Int}(140)
const NOCOLOR = Ref{Bool}(false)

default_width(io = stdout)::Int =
    min(DEFAULT_CONSOLE_WIDTH[], something(ACTIVE_CONSOLE_WIDTH[], displaysize(io)[2]))
default_stacktrace_width(io = stderr)::Int =
    min(DEFAULT_STACKTRACE_WIDTH[], something(ACTIVE_CONSOLE_WIDTH[], displaysize(io)[2]))

const DEFAULT_ASPECT_RATIO = Ref(4 / 3)  # 4:3 - 16:9 - 21:9

# general utils
include("_ansi.jl")
include("__text_utils.jl")
include("_utils.jl")
include("_text_reshape.jl")

# don't import other modules
include("measures.jl")
include("colors.jl")
include("theme.jl")
include("highlight.jl")

const TERM_THEME = Ref(Theme())

# used to disable links in stacktraces for testing
const TERM_SHOW_LINK_IN_STACKTRACE = Ref(true)

function update! end

# rely on other modules
include("style.jl")
include("segments.jl")
include("macros.jl")
include("_code.jl")

# renderables, rely heavily on other modules
include("boxes.jl")
include("console.jl")
include("renderables.jl")
include("layout.jl")
include("link.jl")
include("panels.jl")
include("errors.jl")
include("tprint.jl")
include("trees.jl")
include("dendograms.jl")
include("tables.jl")
include("markdown.jl")
include("repr.jl")
include("compositors.jl")
include("grid.jl")

# interactive
include("Live/live.jl")
include("introspection.jl")
include("progress.jl")
include("logs.jl")
include("prompt.jl")
include("annotations.jl")

export RenderableText, Panel, TextBox, @nested_panels
export TERM_THEME, highlight
export @red, @black, @green, @yellow, @blue, @magenta, @cyan, @white, @default
export @bold, @dim, @italic, @underline, @style
export tprint, tprintln
export install_term_stacktrace,
    install_term_logger, uninstall_term_logger, install_term_repr
export vLine, hLine
export @with_repr, termshow, @showme
export Compositor
export grid
export inspect
export Pager

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

using .Links

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
using .Errors: install_term_stacktrace, render_backtrace, StacktraceContext

using .Logs: install_term_logger, uninstall_term_logger, TermLogger

using .Tprint: tprint, tprintln

using .Trees: Tree

using .Dendograms: Dendogram

using .Tables: Table

using .Compositors: Compositor

using .TermMarkdown: parse_md

using .Repr: @with_repr, termshow, install_term_repr, @showme

using .Grid

# -------------------------------- interactive ------------------------------- #
using .LiveWidgets

# ----------------------------- using interactive ---------------------------- #
using .Progress: ProgressBar, ProgressJob, with, @track

using .Introspection: inspect, typestree, expressiontree, inspect

using .Prompts

include("__precompilation.jl")

end
