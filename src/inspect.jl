import Documenter.DocSystem: getdocs
using InteractiveUtils

include("_inspect.jl")



"""
    TypeInfo

Stores metadata about a DataType
"""
struct TypeInfo
    name::String
    supertypes::Union{Nothing, Tuple}
    subtypes::Union{Nothing, Vector}
    fields::Union{Dict, Nothing}
    constructors::Vector
    methods::Vector  # functions using the target type
    docs::Union{Nothing, Docs.DocStr}
    docstring::String
end

"""
    TypeInfo(type::DataType)

Extracts information from a DataType and stores it as a `TypeInfo` object.
"""
function TypeInfo(type::DataType)
    # get super/sub types
    super = length(supertypes(type)) > 0 ? (supertypes(type)) : nothing
    sub = length(subtypes(type)) > 0 ? subtypes(type) : nothing

    # get docstring
    doc = getdocs(Symbol(type))
    doc = length(doc) > 0 ? doc[1] : nothing
    docstring = isnothing(doc) ? "no docstring" : join_lines(doc.text)
    docstring = highlight(docstring, theme, :docstring)

    # get fields
    if !isabstracttype(type)
        fields = Dict(
            "names" => fieldnames(type),
            "types"=> fieldtypes(type),
        )
    else
        fields = nothing
    end

    # get constructors and methods
    _constructors = split_lines(string(methods(type)))
    constructors = length(_constructors) > 1 ? _constructors[2:end] : []

    _methods = methodswith(type)
    # if length(_methods) > 0
    #     _methods = [string(x) for x in _methods])
    # end

    # @info "GOT INFO" super sub fields constructors _methods doc docstring
    return TypeInfo(string(type), super, sub, fields, constructors, _methods, doc, docstring)
end




"""
    inspect(type::DataType; width::Int=120)

Inspects a type definition to extract info like docstring, fields, types etc.
Also shows constructors for the type and methods making use of the type.
"""
function inspect(type::DataType; width::Int=120, max_n_methods::Int=3)
    # extract type info
    info = TypeInfo(type)

    # ------------------------------ types hierarchy ----------------------------- #
    hierarchy = TextBox(
        "",
        style_super_types(info),
        "",
        style_sub_types(info),
        width=width, 
        title="Types hierarchy", 
        title_style="bold underline yellow"
    )

    # ----------------------------------- docs ----------------------------------- #
    docs = TextBox(
        info.docstring,
        title="Docstring",
        title_style="bold underline yellow",
        width = width
    )

    # ---------------------------------- fields ---------------------------------- #
    if !isnothing(info.fields)
        formatted_fields::Vector{AbstractString} = []
        if !isnothing(info.fields)
            for (name, type) in zip(info.fields["names"], info.fields["types"])
                push!(
                    formatted_fields,
                    "[bold white]$(string(name))[/bold white]"*highlight("::$(type)", theme, :type)
                )
            end
        end

        fields_panel = Panel(
            isnothing(formatted_fields) ? "[dim]No arguments[/dim]" : formatted_fields,
            title="Arguments", 
            title_style="bold yellow",
            style="dim yellow",
            height = max(docs.measure.h, length(formatted_fields)),
            width = width-2,
        )
        insights_panel = (docs / Spacer(width-2, 2) / fields_panel)
    else
        insights_panel = docs
    end

    # ------------------------------- constructors ------------------------------- #
    constructors = do_by_line((x)->style_method_line(x; trim=true), info.constructors)
    n_constructors = length(split_lines(constructors)) > 1 ? Int(length(split_lines(constructors))/2) : 0
    if n_constructors > max_n_methods
        constructors = join_lines(split_lines(constructors)[1:max_n_methods*2])
    end
    constructors = n_constructors > 1 ? constructors : "[dim]No constructors          [/dim]"

    constructors_panel = TextBox(
        constructors,
        title="Constructors[dim]($n_constructors)",
        title_style="bold underline yellow",
        width=width
    )

    # ---------------------------------- methods --------------------------------- #
    if length(info.methods) > 0
        methods = do_by_line(style_method_line, info.methods)
        n_methods = length(split_lines(methods)) > 1 ? Int(length(split_lines(methods))/2) : 1

        if n_methods > max_n_methods
            methods = join_lines(split_lines(methods)[1:max_n_methods*2])
        end
    else
        methods = "[dim]No methods          [/dim]"
        n_methods = 0
    end

    methods_panel = TextBox(
        methods,
        title="Methods[dim]($n_methods)",
        title_style="bold underline yellow",
        width=width
    )

    # ------------------------------- CREATE PANEL ------------------------------- #
    _title = isabstracttype(type) ? " [dim](Abstract)[/dim]" : ""
    panel = Panel(
        Spacer(width-2, 1),
        hierarchy,
        hLine(width-2, "blue"),
        insights_panel,
        hLine(width-2, "blue"),
        constructors_panel,
        hLine(width-2, "blue"),
        methods_panel,
        title="$(typeof(type)): [bold]$(info.name)" * _title, 
        title_style="red",
        style="blue",
    )

    println(
        panel
    )

end