module Repr
using InteractiveUtils
import Markdown
import CodeTracking: @code_string, @which, code_string

import Term:
    str_trunc,
    escape_brackets,
    highlight,
    do_by_line,
    unescape_brackets,
    split_lines,
    TERM_THEME,
    default_width,
    plural,
    reshape_text,
    remove_markup,
    reshape_code_string

import ..Layout: vLine, rvstack, lvstack, Spacer, vstack, cvstack, hLine, pad, hstack
import ..Renderables: RenderableText, info, AbstractRenderable
import ..Consoles: console_width
import ..Panels: Panel, TextBox
import ..Style: apply_style
import ..Tprint: tprint, tprintln
import ..Tables: Table
import ..TermMarkdown: parse_md
import ..Measures: height

export @with_repr, termshow, install_term_repr, @showme

include("_repr.jl")
include("_inspect.jl")

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

Generic method for any object not caught by dedicated methods.
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
        style = TERM_THEME[].repr_panel,
        subtitle_style = TERM_THEME[].repr_name,
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
    content = cvstack(
        "{$(TERM_THEME[].emphasis)}$(highlight(string(e))){/$(TERM_THEME[].emphasis)}",
        hLine(content.measure.w),
        content,
    )
    return print(
        io,
        Panel(
            content;
            fit = true,
            subtitle = escape_brackets(string(typeof(e))),
            subtitle_justify = :right,
            width = 40,
            justify = :center,
            style = TERM_THEME[].repr_panel,
            subtitle_style = TERM_THEME[].repr_name,
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
    _keys = RenderableText.(short_string.(keys(obj)); style = theme.repr_accent * " bold")
    ktypes =
        RenderableText.(
            map(k -> "{{" * short_string(typeof(k)) * "}}", collect(keys(obj)));
            style = theme.repr_type * " dim",
        )
    vals = RenderableText.(short_string.(values(obj)); style = theme.repr_values * " bold")
    vtypes =
        RenderableText.(
            map(k -> "{{" * short_string(typeof(k)) * "}}", collect(values(obj)));
            style = theme.repr_type * " dim",
        )

    content = OrderedDict(
        :type => ktypes,
        :key => _keys,
        :arrow => RenderableText.(fill("=>", length(_keys)); style = theme.operator),
        :value => vals,
        :vtype => vtypes,
    )

    return print(
        io,
        Panel(
            Table(content; show_header = false, box = :NONE, hpad = 0, compact = true);
            fit = true,
            title = escape_brackets(string(typeof(obj))),
            title_justify = :left,
            width = 40,
            justify = :center,
            style = theme.repr_panel,
            title_style = theme.repr_name,
            padding = (2, 2, 1, 1),
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
        "{$(TERM_THEME[].text_accent)}$(size(mtx, 1)) × $(size(mtx, 2)){/$(TERM_THEME[].text_accent)}{default} {/default}",
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
        "{$(TERM_THEME[].text_accent)}$(length(vec)){/$(TERM_THEME[].text_accent)}{default} items{/default}";
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

    panel_style = TERM_THEME[].repr_array_panel
    panel_title_style = TERM_THEME[].repr_array_title

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
                style = panel_style,
                subtitle_style = "default",
                fit = true,
            ),
        )
        push!(panels, Spacer(2, 1))
    end

    if (m = length(I0) - length(I)) > 0
        push!(
            panels,
            Panel(
                "{$panel_title_style bold underline}$m{/$panel_title_style bold underline}{$panel_title_style} $(plural("frame", m)) omitted{/$panel_title_style}";
                width = panels[end - 1].measure.w,
                style = panel_style,
            ),
        )
    end

    return print(
        io,
        repr_panel(
            arr,
            vstack(panels...),
            "{$(TERM_THEME[].text_accent)}" *
            join(string.(size(arr)), " × ") *
            "{/$(TERM_THEME[].text_accent)}",
            fit = true,
        ),
    )
end

"""
---
    termshow(io::IO, obj::DataType; kwargs...)

Show a type's arguments, constructors and docstring.
"""
function termshow(io::IO, obj::DataType; showdocs = true, kwargs...)
    theme = TERM_THEME[]
    ts = theme.repr_type

    field_names, field_types = [], []
    try
        field_names = apply_style.(string.(fieldnames(obj)), theme.repr_accent)
        field_types = apply_style.(map(f -> "::" * string(f), obj.types), ts)
    catch
        field_names = []
        field_types = []
    end

    line = vLine(length(field_names); style = theme.repr_name)
    space = Spacer(length(field_names), 1)
    fields = rvstack(field_names...) * space * lvstack(string.(field_types)...)

    type_name = apply_style(string(obj), theme.repr_name * " bold")
    if length(supertypes(obj)) > 1
        sup = supertypes(obj)[2]
        type_name *= " {$(theme.repr_array_text) dim}<: $sup{/$(theme.repr_array_text) dim}"
    end
    content =
        "    " * repr_panel(
            nothing,
            string(type_name / ("  " * line * fields)),
            nothing;
            fit = false,
            width = min(console_width() - 5, default_width(io)),
            justify = :center,
        )

    print(io, content)

    showdocs && begin
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
        print(io, hLine(console_width(), "Docstring"; style = "green dim", box = :HEAVY))
        tprint(io, doc)
    end
end

"""
---
    termshow(io::IO, fun::Function; kwargs...)

Show a function's methods and docstring.
"""
function termshow(io::IO, fun::Function; width = min(console_width(io), default_width(io)))
    theme = TERM_THEME[]
    # get methods
    methods_contents, N = style_function_methods(fun; width = width)

    m = N - 1
    panel =
        "   " * repr_panel(
            nothing,
            methods_contents,
            "{$(theme.text_accent)}$m{/$(theme.text_accent)} $(plural("method", m))",
            title = "Function: {bold $(theme.repr_array_text)}$(string(fun)){/bold $(theme.repr_array_text)}",
            width = width - 8,
            fit = false,
            justify = :left,
        )
    # @info "made panel" panel.measure  width console_width(io)

    # get docstring 
    doc, _ = get_docstring(fun)
    panel.measure.w < 45 && begin   # handle narrow console 
        doc = replace(string(doc), "```" => " ") |> Markdown.MD
    end
    doc = parse_md(doc; width = panel.measure.w - 4)
    doc = split_lines(doc)
    if (m = length(doc) - 100) > 0
        doc = [
            doc[1:min(100, length(doc))]...,
            "{dim $(theme.repr_array_text)}$m $(plural("line", m)) omitted...{/dim $(theme.repr_array_text)}",
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

# ---------------------------------------------------------------------------- #
#                                    SHOW ME                                   #
# ---------------------------------------------------------------------------- #

macro showme(expr, show_all_methods = false)
    width = min(console_width(), 120)
    hLine(width, style = "dim") |> tprint

    # print info msg
    info_msg = String["""
    !!! note "@showme"
        Showing definition for *method* called by: \n
            $(expr)       
            
    ###### Arguments

    """]

    parse_md(info_msg) |> tprintln

    # print args types
    theme = TERM_THEME[]
    _type_color = theme.type
    _string_color = theme.string
    for i in 2:length(expr.args)
        arg = expr.args[i]
        arg = arg isa AbstractString ? "\"$arg\"" : arg
        "     {$(theme.emphasis)}⨀{/$(theme.emphasis)} {$(theme.text_accent) italic}$arg{/$(theme.text_accent) italic}{$_type_color}::$(typeof(arg)){/$_type_color}" |>
        tprintln
    end

    print("\n")

    quote
        code_source = @code_string $expr
        Markdown.parse("###### Method definition") |> tprintln
        code_source = Markdown.parse("""
        ```
        $code_source
        ```
        """)
        code = parse_md(code_source; width = $width + 2, lpad = false) |> string

        method = @which $expr
        source = "{dim}$(method.file):$(method.line){/dim} "

        rvstack(code, source) |> tprint

        if $show_all_methods
            println()
            tprintln(
                "    " * Panel(
                    style_function_methods(eval(method.name); max_n = 100)[1],
                    title = "all methods",
                    style = "dim",
                    padding = (4, 4, 1, 1),
                    title_style = "default",
                    width = $width - 4,
                ),
            )
        end
    end
end

end
