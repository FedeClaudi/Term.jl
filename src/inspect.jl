
module introspection
using InteractiveUtils

import Term:
    highlight,
    theme,
    escape_brackets,
    join_lines,
    unescape_brackets,
    split_lines,
    do_by_line

import ..consoles: console
import ..panel: Panel, TextBox
import ..layout: Spacer, hLine
include("_inspect.jl")

export inspect

# ---------------------------------------------------------------------------- #
#                                   TYPEINFO                                   #
# ---------------------------------------------------------------------------- #

"""
    TypeInfo

Stores metadata about a DataType
"""
struct TypeInfo
    name::String
    supertypes::Union{Nothing,Tuple}
    subtypes::Union{Nothing,Vector}
    fields::Union{Nothing,Dict}
    constructors::Vector
    methods::Vector  # functions using the target type
    docs::Union{Nothing,Vector{Docs.DocStr}}
    docstring::String
end

"""
    TypeInfo(type::DataType)

Extract information from a DataType and store it as a `TypeInfo` object.
"""
function TypeInfo(type::DataType)
    # get super/sub types
    super = length(supertypes(type)) > 0 ? (supertypes(type)) : nothing
    sub = length(subtypes(type)) > 0 ? subtypes(type) : nothing

    # get docstring
    doc, docstring = get_docstring(Symbol(type))

    # get fields
    if !isabstracttype(type) && length(fieldnames(type)) > 0
        fields = Dict("names" => fieldnames(type), "types" => fieldtypes(type))
    else
        fields = nothing
    end

    # get constructors and methods
    _constructors = split_lines(string(methods(type)))
    constructors = length(_constructors) > 1 ? _constructors[2:end] : []

    _methods = methodswith(type)

    return TypeInfo(
        string(type), super, sub, fields, constructors, _methods, doc, docstring
    )
end

"""
    TypeInfo(fun::Function)

Exctract information from a function object
"""
function TypeInfo(fun::Function)
    # get docstring
    doc, docstring = get_docstring(fun)

    # get methods with same name
    _methods = split_lines(string(methods(fun)))
    _methods = length(_methods) > 1 ? _methods[2:end] : []

    return TypeInfo(string(fun), nothing, nothing, nothing, [], _methods, doc, docstring)
end

# ---------------------------------------------------------------------------- #
#                                    INSPECT                                   #
# ---------------------------------------------------------------------------- #

"""
    inspect(type::DataType; width::Int=120)

Introspect a  type.

Extract  info like docstring, fields, types etc. and show it in a structured
terminal output.
"""
function inspect(
    type::DataType; width::Union{Nothing,Int} = nothing, max_n_methods::Int = 3
)
    width = isnothing(width) ? min(console.width, 92) - 4 : width - 4
    # extract type info
    info = TypeInfo(type)

    # ------------------------------ types hierarchy ----------------------------- #
    hierarchy = TextBox(
        "",
        style_super_types(info),
        "",
        style_sub_types(info);
        width = width,
        title = "Types hierarchy",
        title_style = "bold underline yellow",
    )

    # ----------------------------------- docs ----------------------------------- #
    # @info "making docstirng box" info.docstring width
    docs = TextBox(
        info.docstring;
        title = "Docstring",
        title_style = "bold underline yellow",
        width = width,
    )

    # ---------------------------------- fields ---------------------------------- #
    if !isnothing(info.fields)
        formatted_fields::Vector{AbstractString} = []
        if !isnothing(info.fields)
            for (name, type) in zip(info.fields["names"], info.fields["types"])
                push!(
                    formatted_fields,
                    "[bold white]$(string(name))[/bold white]" *
                    highlight("::$(type)", theme, :type),
                )
            end
        end

        fields_panel = Panel(
            isnothing(formatted_fields) ? "[dim]No arguments[/dim]" : formatted_fields;
            title = "Arguments",
            title_style = "bold yellow",
            style = "dim yellow",
            width = width - 2,
        )
        insights_panel = (docs / Spacer(width - 2, 2) / fields_panel)
    else
        insights_panel = docs
    end

    # ------------------------------- constructors ------------------------------- #
    constructors = do_by_line((x) -> style_method_line(x; trim = true), info.constructors)
    n_constructors = if length(split_lines(constructors)) > 1
        Int(length(split_lines(constructors)) / 2)
    else
        0
    end
    if n_constructors > max_n_methods
        constructors =
            join_lines(split_lines(constructors)[1:(max_n_methods * 2)]) *
            "\n\n[grey53]( additional constructors not shown... )[/grey53]"
    end
    constructors =
        n_constructors > 1 ? constructors : "[dim]No constructors          [/dim]"

    constructors_panel = TextBox(
        constructors;
        title = "Constructors[dim]($n_constructors)",
        title_style = "bold underline yellow",
        width = width,
    )

    # ---------------------------------- methods --------------------------------- #
    if length(info.methods) > 0
        methods = do_by_line(style_method_line, info.methods)
        n_methods =
            length(split_lines(methods)) > 1 ? Int(length(split_lines(methods)) / 2) : 1

        if n_methods > max_n_methods
            methods =
                join_lines(split_lines(methods)[1:(max_n_methods * 2)]) *
                "\n\n[grey53]( additional methods not shown... )[/grey53]"
        end
    else
        methods = "[dim]No methods          [/dim]"
        n_methods = 0
    end

    methods_panel = TextBox(
        methods;
        title = "Methods[dim]($n_methods)",
        title_style = "bold underline yellow",
        width = width,
    )

    # ------------------------------- CREATE PANEL ------------------------------- #
    _title = isabstracttype(type) ? " [dim](Abstract)[/dim]" : ""
    panel = Panel(
        Spacer(width - 2, 1),
        hierarchy,
        hLine(width - 6; style = "blue dim"),
        insights_panel,
        hLine(width - 6; style = "blue dim"),
        constructors_panel,
        hLine(width - 6; style = "blue dim"),
        methods_panel;
        title = "$(typeof(type)): [bold]$(info.name)" * _title,
        title_style = "red",
        style = "blue",
        width = width + 4,
    )

    return println(panel)
end

"""
    inspect(fun::Function; width::Int=88, max_n_methods::Int = 7)

Inspects `Function` objects providing docstrings, and methods signatures.
"""
function inspect(fun::Function; width::Union{Nothing,Int} = nothing, max_n_methods::Int = 7)
    width = isnothing(width) ? min(console.width, 92) : width

    info = TypeInfo(fun)

    # ----------------------------- prepare contents ----------------------------- #
    docs = TextBox(
        info.docstring;
        title = "Docstring",
        title_style = "bold underline yellow",
        width = width - 2,
    )

    if length(info.methods) > 0
        methods = do_by_line(m -> style_method_line(m; trim = true), info.methods)
        n_methods =
            length(split_lines(methods)) > 1 ? Int(length(split_lines(methods)) / 2) : 1

        if n_methods > max_n_methods
            methods =
                join_lines(split_lines(methods)[1:(max_n_methods * 2)]) *
                "\n\n[grey53]( additional methods not shown... )[/grey53]"
        end
    else
        methods = "[dim]No methods          [/dim]"
        n_methods = 0
    end

    methods_panel = TextBox(
        methods;
        title = "Methods[dim]($n_methods)",
        title_style = "bold underline yellow",
        width = width - 2,
    )

    # -------------------------------- print panel ------------------------------- #
    return println(
        Panel(
            Spacer(width - 2, 1),
            docs,
            hLine(width - 6; style = "blue dim"),
            methods_panel;
            title = "Function: [bold red]$(info.name)[/bold red]",
            title_style = "red",
            style = "blue",
            width = width,
        ),
    )
end

"""
generic inspect method, dispatches to type-specific methods when they can be found
"""
function inspect(obj; kwargs...)
    if typeof(obj) <: Function
        inspect(obj; kwargs...)
    elseif typeof(typeof(obj)) == DataType
        inspect(typeof(obj); kwargs...)
    else
        throw("Cannot inspect $obj ($(typeof(obj)))")
    end
end
end
