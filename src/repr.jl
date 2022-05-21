module Repr
import Term: escape_brackets, truncate
import ..panel: Panel
import ..renderables: RenderableText
import ..layout: vLine, rvstack, lvstack, Spacer

export @with_repr

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
    clean_str = (escape_brackets ∘ string)
    showfn = begin
        :(function Base.show(io::IO, ::MIME"text/plain", obj::$tn)
            field_names = fieldnames(typeof(obj))
            field_types = map(f -> "::" * string(f), typeof(obj).types)
            _values = map(f->getfield(obj, f), field_names)

            fields = RenderableText.(string.(field_names); style="bold #e0db79")      
            field_types = RenderableText.(field_types; style="#bb86db")      
            values = []
            for val in _values
                val = $truncate($clean_str(val), 45)
                push!(values, RenderableText.(val; style="bright_blue"))
            end
            
            line = vLine(length(fields); style="dim #7e9dd9")
            space = Spacer(1, length(fields))
            

            print(io,
                Panel(
                    rvstack(fields...) * lvstack(field_types...) * line * space * lvstack(values...);
                    fit=false, subtitle=string(typeof(obj)), subtitle_justify=:right, width=40,
                    justify=:center, style="#9bb3e0", subtitle_style="#e3ac8d"
                )
            )
        end)
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
    quote
        $typedef 
        $showfn
    end
end


macro with_repr(typedef)
    return esc(with_repr(typedef))
end
end