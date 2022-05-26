module Repr


import Term: truncate, escape_brackets, theme, highlight
import ..Tprint: tprint
import ..panel: Panel
import ..renderables: RenderableText
import ..layout: vLine, rvstack, lvstack, Spacer, vstack, cvstack
import ..style: apply_style

export @with_repr, termshow, install_term_repr



accent_style = "bold #e0db79"
name_style = "#e3ac8d"
type_style = "#bb86db"
values_style = "#b3d4ff"
line_style = "dim #7e9dd9"
panel_style = "#9bb3e0"

"""
    typename(typedef::Expr)

Get the name of a type as an expression
"""
function typename(typedef::Expr)
    if typedef.args[2] isa Symbol
        return typedef.args[2]
    elseif typedef.args[2].args[1] isa Symbol
        return typedef.args[2].args[1]
    elseif typedef.args[2].args[1].args[1] isa Symbol
        return typedef.args[2].args[1].args[1]
    else
        error("Could not parse type-head from: $typedef")
    end
end


function termshow(io::IO, obj)
    field_names = fieldnames(typeof(obj))
    if length(field_names) == 0
        print(io, 
            RenderableText("$obj{$type_style}::$(typeof(obj)){/$type_style}")
        )
        return
    end
    field_types = map(f -> "::" * string(f), typeof(obj).types)
    _values = map(f->getfield(obj, f), field_names)

    fields = map(
        ft -> RenderableText(
            apply_style(string(ft[1]), accent_style) * apply_style(string(ft[2]), type_style)
        ), zip(field_names, field_types)
    ) 
         
    values = []
    for val in _values
        val = truncate(string(val), 45)
        push!(values, RenderableText.(val; style=values_style))
    end

    line = vLine(length(fields); style=line_style)
    space = Spacer(1, length(fields))
 
    print(io, Panel(
            rvstack(fields...) * line * space * lvstack(values...);
            fit=false, 
            subtitle=escape_brackets(string(typeof(obj))), 
            subtitle_justify=:right, 
            width=40,
            justify=:center, 
            style=panel_style, 
            subtitle_style=name_style
        )
    )
end

termshow(obj) = termshow(stdout, obj)



function termshow(io::IO, obj::AbstractDict)
    short_string(x) = truncate(string(x), 30)
    # prepare text renderables
    k = RenderableText.(short_string.(keys(obj)); style=accent_style * " bold")
    ktypes = RenderableText.(
        map(k -> "{{" * short_string(typeof(k)) * "}}", collect(keys(obj)));
        style=type_style * " dim"
        )
    vals = RenderableText.(short_string.(values(obj)); style=values_style * " bold")
    vtypes = RenderableText.(
        map(k -> "{{" * short_string(typeof(k)) * "}}", collect(values(obj)));
        style=type_style * " dim"
        )

    # trim if too many
    if length(k) > 10
        k, ktypes, vals, vtypes = k[1:10], ktypes[1:10], vals[1:10], vtypes[1:10]

        push!(k, RenderableText("⋮"; style=accent_style))
        push!(ktypes, RenderableText("⋮"; style=type_style * " dim"))
        push!(vals, RenderableText("⋮"; style=values_style))
        push!(vtypes, RenderableText("⋮"; style=type_style * " dim"))

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
            justify=:center, style=panel_style, title_style=name_style,
            padding=(2, 2, 1, 1), 
            subtitle = "{bold white}$(length(keys(obj))){/bold white}{default} items{/default}",
            subtitle_justify=:right
        )
    )
end



function vec_elems2renderables(v::Union{Tuple, AbstractVector}, N, max_w)
    shortsting(x) = truncate(string(x), max_w)
    out = RenderableText.(
        highlight.(
            shortsting.(
            v[1:N]
        ))
    )

    length(v) > N && push!(
        out,
        RenderableText("⋮";)
    )
    return cvstack(out...)
end

function repr_panel(obj, content, subtitle)
    return  Panel(
        content;
        fit=false, 
        title=escape_brackets(string(
            typeof(obj)
            )), 
        title_justify=:left, 
        width=40,
        justify=:center, 
        style=panel_style, 
        title_style=name_style,
        padding=(2, 2, 1, 1), 
        subtitle = subtitle,
        subtitle_justify=:right
    )
end

function matrix2content(mtx::AbstractMatrix; max_w=12, max_items=100, max_D=10)
    N = min(max_items, size(mtx, 1))
    D = min(max_D, size(mtx, 2))

    columns = [
        vec_elems2renderables(mtx[:, i], N, max_w)
        for i in 1:D
    ]
    counts = RenderableText.("(" .* string.(1:N) .* ")"; style="dim")
    top_counts = RenderableText.("(" .* string.(1:D) .* ")"; style="dim white bold")

    space1, space2 = Spacer(3, length(counts)), Spacer(2, length(counts))

    content = ("" / ""/ rvstack(counts...)) * space1 
    for i in 1:D-1
        content *= cvstack(top_counts[i], "", lvstack(columns[i])) * space2
    end
    content *= cvstack(top_counts[end], "", lvstack(columns[end]))

    if D < size(mtx, 2)
        content *= ""/ ""/  vstack((" {bold}⋯{/bold}" for i in 1:N)...)
    end
    return content
end

function vec2content(vec::Union{Tuple, AbstractVector})
    max_w = 88
    max_items = 100
    N = min(max_items, length(vec))

    if N == 0
        return "{bright_blue}empty vector{/bright_blue}"
    end

    vec_items = vec_elems2renderables(vec, N, max_w)
    counts = RenderableText.("(" .* string.(1:N) .* ")"; style="dim")

    content = rvstack(counts...) * Spacer(3, length(counts)) * cvstack(
        vec_items
    )
    return content
end


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
    I = CartesianIndices(size(arr)[3:end])
    I = I[1:min(10, length(I))]

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
    print(io, repr_panel(
        arr, vstack(panels...),
        "{white}" * join(string.(size(arr)), " × ") * "{/white}"
    ))

end


function install_term_repr()
    @eval begin
        function Base.show(io::IO, ::MIME"text/plain", text::AbstractString)
            tprint(io, "{$(theme.string)}" * text * "{/$(theme.string)}"; highlight=true)
        end

        function Base.show(io::IO, ::MIME"text/plain", num::Number)
            tprint(io, string(num); highlight=true)
        end

        function Base.show(io::IO,  num::Number)
            tprint(io, string(num); highlight=true)
        end


        function Base.show(io::IO, ::MIME"text/plain", obj)
            termshow(io, obj)
        end

        function Base.show(io::IO, ::MIME"text/plain", obj::AbstractDict)
            termshow(io, obj)
        end

        function Base.show(io::IO, ::MIME"text/plain", obj::Union{AbstractArray, AbstractMatrix})
            termshow(io, obj)
        end
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