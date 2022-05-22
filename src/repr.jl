module Repr
import Term: truncate
import ..panel: Panel
import ..renderables: RenderableText
import ..layout: vLine, rvstack, lvstack, Spacer
import ..style: apply_style

export @with_repr, termshow

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
        print(io, apply_style(string(typeof(obj)), "#e3ac8d"))
        return
    end
    field_types = map(f -> "::" * string(f), typeof(obj).types)
    _values = map(f->getfield(obj, f), field_names)

    fields = map(
        ft -> RenderableText(
            apply_style(string(ft[1]), "bold #e0db79") * apply_style(string(ft[2]), "#bb86db")
        ), zip(field_names, field_types)
    ) 
         
    values = []
    for val in _values
        val = truncate(string(val), 45)
        push!(values, RenderableText.(val; style="#b3d4ff"))
    end

    line = vLine(length(fields); style="dim #7e9dd9")
    space = Spacer(1, length(fields))
 
    print(io, Panel(
            rvstack(fields...) * line * space * lvstack(values...);
            fit=false, subtitle=string(typeof(obj)), subtitle_justify=:right, width=40,
            justify=:center, style="#9bb3e0", subtitle_style="#e3ac8d"
        )
    )
end
termshow(obj) = termshow(stdout, obj)


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