module Repr


import Term: truncate,
            escape_brackets,
            highlight,
            do_by_line,
            unescape_brackets,
            split_lines,
            term_theme            

import ..Tprint: tprint
import ..panel: Panel, TextBox
import ..renderables: RenderableText
import ..layout: vLine, rvstack, lvstack, Spacer, vstack, cvstack
import ..style: apply_style
import ..console: console_width

export @with_repr, termshow, install_term_repr



include("_repr.jl")
include("_inspect.jl")

function termshow(io::IO, obj)
    field_names = fieldnames(typeof(obj))
    if length(field_names) == 0
        print(io, 
            RenderableText("$obj{$theme.repr_type_style}::$(typeof(obj)){/$theme.repr_type_style}")
        )
        return
    end
    field_types = map(f -> "::" * string(f), typeof(obj).types)
    _values = map(f->getfield(obj, f), field_names)

    fields = map(
        ft -> RenderableText(
            apply_style(string(ft[1]), term_theme[].repr_accent_style) * apply_style(string(ft[2]), term_theme[].repr_type_style)
        ), zip(field_names, field_types)
    ) 
         
    values = []
    for val in _values
        val = truncate(string(val), 45)
        push!(values, RenderableText.(val; style=term_theme[].repr_values_style))
    end

    line = vLine(length(fields); style=term_theme[].repr_line_style)
    space = Spacer(1, length(fields))
 
    print(io, Panel(
            rvstack(fields...) * line * space * lvstack(values...);
            fit=false, 
            subtitle=escape_brackets(string(typeof(obj))), 
            subtitle_justify=:right, 
            width=40,
            justify=:center, 
            style=term_theme[].repr_panel_style, 
            subtitle_style=term_theme[].repr_name_style
        )
    )
end


termshow(obj) = termshow(stdout, obj)


# ---------------------------------------------------------------------------- #
#                                  DICTIONARY                                  #
# ---------------------------------------------------------------------------- #
function termshow(io::IO, obj::AbstractDict)
    short_string(x) = truncate(string(x), 30)
    # prepare text renderables
    k = RenderableText.(short_string.(keys(obj)); style=term_theme[].repr_accent_style * " bold")
    ktypes = RenderableText.(
        map(k -> "{{" * short_string(typeof(k)) * "}}", collect(keys(obj)));
        style=term_theme[].repr_type_style * " dim"
        )
    vals = RenderableText.(short_string.(values(obj)); style=term_theme[].repr_values_style * " bold")
    vtypes = RenderableText.(
        map(k -> "{{" * short_string(typeof(k)) * "}}", collect(values(obj)));
        style=term_theme[].repr_type_style * " dim"
        )

    # trim if too many
    if length(k) > 10
        k, ktypes, vals, vtypes = k[1:10], ktypes[1:10], vals[1:10], vtypes[1:10]

        push!(k, RenderableText("⋮"; style=term_theme[].repr_accent_style))
        push!(ktypes, RenderableText("⋮"; style=term_theme[].repr_type_style * " dim"))
        push!(vals, RenderableText("⋮"; style=term_theme[].repr_values_style))
        push!(vtypes, RenderableText("⋮"; style=term_theme[].repr_type_style * " dim"))

        arrows = vstack(RenderableText.(repeat(["=>"], length(k)-1); style="red bold")...)
    else
        arrows = vstack(RenderableText.(repeat(["=>"], length(k)); style="red bold")...)

    end

    # prepare other renderables
    space = Spacer(1, length(k))
    line = vLine(length(k); style="dim #7e9dd9")

    _keys_renderables = cvstack(ktypes...) * line * space * cvstack(k...)
    _values_renderables = cvstack(vals...) * space *  line * cvstack(vtypes...);

    print(io, Panel(
        _keys_renderables * space*arrows*space *  _values_renderables;
            fit=false, title=escape_brackets(string(typeof(obj))), title_justify=:left, width=40,
            justify=:center, style=term_theme[].repr_panel_style, title_style=term_theme[].repr_name_style,
            padding=(2, 2, 1, 1), 
            subtitle = "{bold white}$(length(keys(obj))){/bold white}{default} items{/default}",
            subtitle_justify=:right
        )
    )
end


# ---------------------------------------------------------------------------- #
#                                ABSTRACT ARRAYS                               #
# ---------------------------------------------------------------------------- #
function termshow(io::IO, mtx::AbstractMatrix)
    print(io, repr_panel(
        mtx, matrix2content(mtx), "{bold white}$(size(mtx, 1)) × $(size(mtx, 2)){/bold white}{default} {/default}",
    ))
end

function termshow(io::IO, vec::Union{Tuple, AbstractVector})
    print(io, 
        repr_panel(
            vec, vec2content(vec),
                "{bold white}$(length(vec)){/bold white}{default} items{/default}",
            )
    )
end

function termshow(io::IO, arr::AbstractArray)
    I0 = CartesianIndices(size(arr)[3:end])
    I = I0[1:min(10, length(I0))]

    panels::Vector{Union{Panel, Spacer}} = []
    for (n, i) in enumerate(I)
        i_string = join([string(i) for i in Tuple(i)], ", ")
        push!(
            panels, Panel(
                matrix2content(arr[:, :, i]; max_w=60, max_items=25, max_D=5),
                subtitle="[:, :, $i_string]",
                subtitle_justify=:right,
                width=22, style="dim yellow",
                subtitle_style="default",
                title="($n)", title_style="dim bright_blue"
                )
        )
        push!(panels, Spacer(1, 2))
    end

    if length(I0) > length(I)
        push!(
            panels, Panel(
                "{dim bright_blue bold underline}$(length(I0) - length(I)){/dim bright_blue bold underline}{dim bright_blue} frames omitted{/dim bright_blue}",
                width=panels[end-1].measure.w, style="dim yellow",
                )
        )
    end

    print(io, repr_panel(
        arr, vstack(panels...),
        "{white}" * join(string.(size(arr)), " × ") * "{/white}"
    ))

end


function termshow(io::IO, fun::Function)
    # get docstring 
    doc, docstring = get_docstring(fun)
    doc = highlight("{#8dbd86}" * string(doc) * "{/#8dbd86}")
    doc = split_lines(doc)
    if length(doc) > 5
        doc = [doc[1:min(5, length(doc))]..., 
            "{dim bright_blue}$(length(doc)-5) lines omitted...{/dim bright_blue}"
        ]
    end

    # get methods
    _methods = split_lines(string(methods(fun)))
    N = length(_methods)
    _methods = length(_methods) > 1 ? _methods[2:min(11, N)] : []
    _methods = map(
        m -> join(split(join(split(m, "]")[2:end]), " in ")[1]),
        _methods
    )
    _methods = map(
        m -> replace(m, string(fun)=>"{bold #a5c6d9}$(string(fun)){/bold #a5c6d9}", count=1), 
        _methods
    )
    counts = RenderableText.("(" .* string.(1:length(_methods)) .* ") "; style="bold dim")
    length(_methods) < N-1 && push!(
        _methods,
        "\n{bold dim bright_blue}$(N - length(_methods)-1){/bold dim bright_blue}{dim bright_blue} methods omitted...{/dim bright_blue}"
    )

    panel = repr_panel(
        nothing, 
        rvstack(counts...) * lvstack(RenderableText.(highlight.(_methods))...), 
        "{white bold}$(N-1){/white bold} methods")
    print(io, cvstack(
        panel, 
        TextBox(doc; width=panel.measure.w)
        )
    )

end

# ---------------------------------------------------------------------------- #
#                                 INSTALL REPR                                 #
# ---------------------------------------------------------------------------- #
function install_term_repr()
    @eval begin
        function Base.show(io::IO, ::MIME"text/plain", num::Number)
            tprint(io, string(num); highlight=true)
        end

        function Base.show(io::IO,  num::Number)
            tprint(io, string(num); highlight=true)
        end


        function Base.show(io::IO, ::MIME"text/plain", obj::AbstractDict)
            termshow(io, obj)
        end

        function Base.show(io::IO, ::MIME"text/plain", obj::Union{AbstractArray, AbstractMatrix})
            termshow(io, obj)
        end

        function Base.show(io::IO, ::MIME"text/plain", fun::Function)
            termshow(io, fun)
        end
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
    showfn = begin
        :(function Base.show(io::IO, ::MIME"text/plain", obj::$tn)
            termshow(io, obj)
        end)
    end

    quote
        $typedef 
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
macro with_repr(typedef)
    return esc(with_repr(typedef))
end
end