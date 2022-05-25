module Repr
import Term: truncate, escape_brackets, theme, tprint
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
            fit=false, subtitle=string(typeof(obj)), subtitle_justify=:right, width=40,
            justify=:center, style=panel_style, subtitle_style=name_style
        )
    )
end

termshow(obj) = termshow(stdout, obj)



function termshow(io::IO, obj::AbstractDict)
    # prepare text renderables
    k = RenderableText.(string.(keys(obj)); style=accent_style * " bold")
    ktypes = RenderableText.(
        map(k -> "{{" * string(typeof(k)) * "}}", collect(keys(obj)));
        style=type_style * " dim"
        )
    vals = RenderableText.(string.(values(obj)); style=values_style * " bold")
    vtypes = RenderableText.(
        map(k -> "{{" * string(typeof(k)) * "}}", collect(values(obj)));
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

function install_term_repr()
    @eval begin

        function Base.show(io::IO, ::MIME"text/plain", text::AbstractString)
            tprint(io, text; highlight=true)
        end

        function Base.show(io::IO, ::MIME"text/plain", obj)
            termshow(io, obj)
        end

        function Base.show(io::IO, ::MIME"text/plain", obj::AbstractDict)
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