module Repr
using InteractiveUtils

import Term:
    str_trunc,
    escape_brackets,
    highlight,
    do_by_line,
    unescape_brackets,
    split_lines,
    TERM_THEME,
    default_width

import ..Layout: vLine, rvstack, lvstack, Spacer, vstack, cvstack, hLine, pad
import ..Renderables: RenderableText, info, AbstractRenderable
import ..Consoles: console_width
import ..Panels: Panel, TextBox
import ..Style: apply_style
import ..Tprint: tprint
import ..Tables: Table
import ..TermMarkdown: parse_md

export @with_repr, termshow, install_term_repr

include("_repr.jl")
include("_inspect.jl")

plural(word::AbstractString, n) = n == 1 ? word : word * 's'

"""
    termshow

Styled string representation of any object.

`termshow` prints to stdout (or any other IO) a styled
representation of the object.
Dedicated methods create displays for specify types such as `Dict`
or `Vector`.
"""
function termshow end

"""
---
    termshow(io::IO, obj)

Generic method for any object not caught my dedicated methods.
Creates a `Panel` with the object's fields and contents.
"""
termshow(io::IO, obj) = print(
    io,
    Panel(
        repr_get_obj_fields_display(obj);
        fit = true,
        subtitle = escape_brackets(string(typeof(obj))),
        subtitle_justify = :right,
        width = 40,
        justify = :center,
        style = TERM_THEME[].repr_panel_style,
        subtitle_style = TERM_THEME[].repr_name_style,
    ),
)

termshow(obj; kwargs...) = termshow(stdout, obj; kwargs...)

# ---------------------------------------------------------------------------- #
#                                     EXPR                                     #
# ---------------------------------------------------------------------------- #
"""
---
    termshow(io::IO, e::Expr; kwargs...)

Show an expression's head and arguments.
"""
function termshow(io::IO, e::Expr; kwargs...)
    content = repr_get_obj_fields_display(e)
    content =
        cvstack("{green}$(highlight(string(e))){/green}", hLine(content.measure.w), content)
    return print(
        io,
        Panel(
            content;
            fit = true,
            subtitle = escape_brackets(string(typeof(e))),
            subtitle_justify = :right,
            width = 40,
            justify = :center,
            style = TERM_THEME[].repr_panel_style,
            subtitle_style = TERM_THEME[].repr_name_style,
        ),
    )
end

# ---------------------------------------------------------------------------- #
#                                  DICTIONARY                                  #
# ---------------------------------------------------------------------------- #
"""
---
    termshow(io::IO, d::Dict; kwargs...)

Show a dictionary's keys and values and their data types.
"""
function termshow(io::IO, obj::AbstractDict; kwargs...)
    short_string(x) = str_trunc(string(x), 30)
    theme = TERM_THEME[]

    # prepare text renderables
    k = RenderableText.(short_string.(keys(obj)); style = theme.repr_accent_style * " bold")
    ktypes =
        RenderableText.(
            map(k -> "{{" * short_string(typeof(k)) * "}}", collect(keys(obj)));
            style = theme.repr_type_style * " dim",
        )
    vals =
        RenderableText.(
            short_string.(values(obj));
            style = theme.repr_values_style * " bold",
        )
    vtypes =
        RenderableText.(
            map(k -> "{{" * short_string(typeof(k)) * "}}", collect(values(obj)));
            style = theme.repr_type_style * " dim",
        )

    # trim if too many
    arrows = if length(k) > 10
        k, ktypes, vals, vtypes = k[1:10], ktypes[1:10], vals[1:10], vtypes[1:10]

        push!(k, RenderableText("⋮"; style = theme.repr_accent_style))
        push!(ktypes, RenderableText("⋮"; style = theme.repr_type_style * " dim"))
        push!(vals, RenderableText("⋮"; style = theme.repr_values_style))
        push!(vtypes, RenderableText("⋮"; style = theme.repr_type_style * " dim"))

        vstack(RenderableText.(fill("=>", length(k) - 1); style = "red bold")...)
    else
        vstack(RenderableText.(fill("=>", length(k)); style = "red bold")...)
    end

    # prepare other renderables
    space = Spacer(length(k), 1)
    line = vLine(length(k); style = "dim #7e9dd9")

    _keys_renderables = cvstack(ktypes...) * line * space * cvstack(k...)
    _values_renderables = cvstack(vals...) * space * line * cvstack(vtypes...)

    m = length(keys(obj))
    return print(
        io,
        Panel(
            _keys_renderables * space * arrows * space * _values_renderables;
            fit = true,
            title = escape_brackets(string(typeof(obj))),
            title_justify = :left,
            width = 40,
            justify = :center,
            style = theme.repr_panel_style,
            title_style = theme.repr_name_style,
            padding = (2, 2, 1, 1),
            subtitle = "{bold white}$m{/bold white}{default} $(plural("item", m)){/default}",
            subtitle_justify = :right,
        ),
    )
end

# ---------------------------------------------------------------------------- #
#                                ABSTRACT ARRAYS                               #
# ---------------------------------------------------------------------------- #
"""
---
    termshow(io::IO, mtx::AbstractMatrix; kwargs...)

Show a matrix content as a 2D table visualization.
"""
termshow(io::IO, mtx::AbstractMatrix; kwargs...) = print(
    io,
    repr_panel(
        mtx,
        matrix2content(mtx),
        "{bold white}$(size(mtx, 1)) × $(size(mtx, 2)){/bold white}{default} {/default}",
    ),
)

"""
---
    termshow(io::IO, vec::Union{Tuple,AbstractVector}; kwargs...)

Show a vector's content as a 1D table visualization.
"""
termshow(io::IO, vec::Union{Tuple,AbstractVector}; kwargs...) = print(
    io,
    repr_panel(
        vec,
        vec2content(vec),
        "{bold white}$(length(vec)){/bold white}{default} items{/default}";
        justify = :left,
        fit = true,
        title = nothing,
    ),
)

"""
---
    termshow(io::IO, arr::AbstractArray; kwargs...)

Show the content of a multidimensional array as a series of 2D slices.
"""
function termshow(io::IO, arr::AbstractArray; kwargs...)
    I0 = CartesianIndices(size(arr)[3:end])
    I = I0[1:min(10, length(I0))]

    panels::Vector{Union{Panel,Spacer}} = []
    for (n, i) in enumerate(I)
        i_string = join(string.(Tuple(i)), ", ")
        push!(
            panels,
            Panel(
                matrix2content(arr[:, :, i]; max_w = 60, max_items = 25, max_D = 5);
                subtitle = "[:, :, $i_string]",
                subtitle_justify = :right,
                width = 60,
                style = "dim yellow",
                subtitle_style = "default",
                title = "($n)",
                title_style = "dim bright_blue",
            ),
        )
        push!(panels, Spacer(2, 1))
    end

    if (m = length(I0) - length(I)) > 0
        push!(
            panels,
            Panel(
                "{dim bright_blue bold underline}$m{/dim bright_blue bold underline}{dim bright_blue} $(plural("frame", m)) omitted{/dim bright_blue}";
                width = panels[end - 1].measure.w,
                style = "dim yellow",
            ),
        )
    end

    return print(
        io,
        repr_panel(
            arr,
            vstack(panels...),
            "{white}" * join(string.(size(arr)), " × ") * "{/white}",
            fit = true,
        ),
    )
end

"""
---
    termshow(io::IO, obj::DataType; kwargs...)

Show a type's arguments, constructors and docstring.
"""
function termshow(io::IO, obj::DataType; kwargs...)
    theme = TERM_THEME[]
    ts = theme.repr_type_style
    field_names = apply_style.(string.(fieldnames(obj)), theme.repr_accent_style)
    field_types = apply_style.(map(f -> "::" * string(f), obj.types), ts)

    line = vLine(length(field_names); style = theme.repr_name_style)
    space = Spacer(length(field_names), 1)
    fields = rvstack(field_names...) * space * lvstack(string.(field_types)...)

    type_name = apply_style(string(obj), theme.repr_name_style * " bold")
    sup = supertypes(obj)[2]
    type_name *= " {bright_blue dim}<: $sup{/bright_blue dim}"
    content =
        "    " * repr_panel(
            nothing,
            string(type_name / ("  " * line * fields)),
            nothing;
            fit = false,
            width = min(console_width() - 5, default_width(io)),
            justify = :center,
        )

    # get docstring
    doc, _ = get_docstring(obj)
    doc = parse_md(doc; width = min(100, console_width()))
    doc = split_lines(doc)
    if (m = length(doc) - 100) > 0
        doc = [
            doc[1:min(100, length(doc))]...,
            "{dim bright_blue}$m $(plural("line", m)) omitted...{/dim bright_blue}",
        ]
    end
    doc = join(doc, "\n")

    print(io, content)
    print(io, hLine(console_width(), "Docstring"; style = "green dim", box = :HEAVY))
    tprint(io, doc)
end

"""
---
    termshow(io::IO, fun::Function; kwargs...)

Show a function's methods and docstring.
"""
function termshow(io::IO, fun::Function; width = min(console_width(io), default_width(io)))
    # get methods
    _methods = split_lines(string(methods(fun)))
    N = length(_methods)

    _methods = length(_methods) > 1 ? _methods[2:min(11, N)] : []
    _methods = map(m -> join(split(join(split(m, "]")[2:end]), " in ")[1]), _methods)
    _methods = map(
        m -> replace(
            m,
            string(fun) => "{bold #a5c6d9}$(string(fun)){/bold #a5c6d9}";
            count = 1,
        ),
        _methods,
    )
    counts = RenderableText.("(" .* string.(1:length(_methods)) .* ") "; style = "bold dim")
    if (m = N - length(_methods) - 1) > 0
        push!(
            _methods,
            "\n{bold dim bright_blue}$m{/bold dim bright_blue}{dim bright_blue} $(plural("method", m)) omitted...{/dim bright_blue}",
        )
    end
    methods_contents = if N > 1
        methods_texts = RenderableText.(highlight.(_methods); width = width - 20)
        # rvstack(counts...) * lvstack(...)
        join(string.(map(i -> counts[i] * methods_texts[i], 1:length(counts))), '\n')
    else
        fun |> methods |> string |> split_lines |> first
    end

    m = N - 1
    panel =
        "   " * repr_panel(
            nothing,
            methods_contents,
            "{white bold}$m{/white bold} $(plural("method", m))",
            title = "Function: {bold bright_blue}$(string(fun)){/bold bright_blue}",
            width = width - 8,
            fit = false,
            justify = :left,
        )
    # @info "made panel" panel.measure  width console_width(io)

    # get docstring 
    doc, _ = get_docstring(fun)
    doc = parse_md(doc; width = panel.measure.w - 4)
    doc = split_lines(doc)
    if (m = length(doc) - 100) > 0
        doc = [
            doc[1:min(100, length(doc))]...,
            "{dim bright_blue}$m $(plural("line", m)) omitted...{/dim bright_blue}",
        ]
    end
    print(io, panel)
    print(io, hLine(panel.measure.w, "Docstring"; style = "green dim", box = :HEAVY))
    print(io, "   " * RenderableText(join(doc, "\n"), width = width - 4))
end

# ---------------------------------------------------------------------------- #
#                                 INSTALL REPR                                 #
# ---------------------------------------------------------------------------- #
"""
    install_term_repr()

Make `term_show` be called every times something is shown in the REPL
"""
function install_term_repr()
    @eval begin
        import Term: termshow

        Base.show(io::IO, ::MIME"text/plain", num::Number) =
            tprint(io, string(num); highlight = true)

        Base.show(io::IO, num::Number) = tprint(io, string(num); highlight = true)

        Base.show(io::IO, ::MIME"text/plain", obj::AbstractDict) = termshow(io, obj)

        Base.show(io::IO, ::MIME"text/plain", obj::Union{AbstractArray,AbstractMatrix}) =
            termshow(io, obj)

        Base.show(io::IO, ::MIME"text/plain", fun::Function) = termshow(io, fun)

        Base.show(io::IO, ::MIME"text/plain", obj::DataType) = termshow(io, obj)

        Base.show(io::IO, ::MIME"text/plain", expr::Expr) = termshow(io, expr)
    end
end

# ---------------------------------------------------------------------------- #
#                                   WITH REPR                                  #
# ---------------------------------------------------------------------------- #

"""
    with_repr(typedef::Expr)

Function for the macro @with_repr which creates a `Base.show` method for a type.

The `show` method shows the field names/types for the 
type and the values of the fields.

# Example
```
@with_repr struct TestStruct2
    x::Int
    name::String
    y
end
```
"""
function with_repr(typedef::Expr)
    tn = typename(typedef) # the name of the type
    showfn = :(Base.show(io::IO, ::MIME"text/plain", obj::$tn) = termshow(io, obj))
    quote
        Core.@__doc__ $typedef
        $showfn
    end
end

"""
with_repr(typedef::Expr)

Function for the macro @with_repr which creates a `Base.show` method for a type.

The `show` method shows the field names/types for the 
type and the values of the fields.

# Example
```
@with_repr struct TestStruct2
x::Int
name::String
y
end
```
"""
macro with_repr(typedef::Expr)
    return esc(with_repr(typedef))
end

end
