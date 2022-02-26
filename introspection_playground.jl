using Revise
Revise.revise()
import Documenter.DocSystem: getdocs
using Term
import Term: Panel, TextBox, Spacer, hLine, hstack, split_lines, join_lines, do_by_line, RenderableText
import Term: int

"""
    TypeInfo

Stores metadata about a DataType
"""
struct TypeInfo
    name::String
    supertypes::Union{Nothing, Tuple}
    subtypes::Union{Nothing, Tuple}
    fields::Union{Dict, Nothing}
    constructors::Vector
    methods::Vector  # functions using the target type
    docs::Union{Nothing, Docs.DocStr}
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
    constructors = split_lines(string(methods(type)))[2:end]

    _methods = methodswith(type)
    if length(_methods) > 0
        _methods = join_lines([string(x) for x in _methods])
    end

    return TypeInfo(string(type), super, sub, fields, constructors, _methods, doc)
end


function style_super_types(info::TypeInfo)::String
    if !isnothing(info.supertypes)
        stypes = "[dim](supertypes):[/dim] [bold blue]$(info.name)[/bold blue]"
        for sup in info.supertypes[2:end]
            abstract = isabstracttype(sup) ? "underline" : ""
            name = split(string(sup), ".")[end]
            stypes = stypes * "[blue] <[/blue] [bold $abstract]$name[/bold $abstract]"
        end
    else
        stypes = "[dim](supertypes): no super types[/dim]"
    end
    return stypes
end


function style_sub_types(info::TypeInfo)::String
    if !isnothing(info.subtypes)
        subtypes = "  [dim](subtypes):[/dim] "
        for sub in info.subtypes
            name = split(string(sub), ".")[end]
            subtypes *= "[bold]$name[/bold]"
        end
        subtypes = subtypes * " [blue]> [/blue][bold blue]$(info.name)[/bold blue]"
    else
        subtypes = "  [dim](subtypes): no subtypes[/dim]"
    end
    return subtypes
end


function style_method_line(method::AbstractString)
    if length(method) == 0
        return method
    end
    name = split(method[4:end], " in ")[1]
    name, arguments = split(name, "(")
    arguments = "("*arguments
    rest = split(method, name)[end]

    text, file = split(rest, "at")

    info = "[$(theme.emphasis)]$(name)[/$(theme.emphasis)][$(theme.emphasis_light)]$(highlight(arguments, theme))[/$(theme.emphasis_light)]"

    method = "$info\n[dim]      $file"

    return method
end



function inspect(type::DataType, width=120)
    info = TypeInfo(type)


    # make textbox showing types hierarchy
    hierarchy = TextBox(
        "",
        style_super_types(info),
        "",
        style_sub_types(info),
        width=width, 
        title="Types hierarchy", 
        title_style="bold underline yellow"
    )

    docs = TextBox(
        highlight(info.docs.text[1], theme, :docstring),
        title="Docstring",
        title_style="bold underline yellow",
        width = width
    )

    # panel showing type's field
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

    insights_panel = docs / Spacer(width-2, 2) / fields_panel

  
    # type's constructors
    constructors = do_by_line(style_method_line, info.constructors)
    nmethods = length(split_lines(constructors)) > 1 ? Int(length(split_lines(constructors))/2) : 1
    constructors = nmethods > 1 ? constructors : "[dim]No constructors          [/dim]"
    constructors_panel = TextBox(
        constructors,
        title="Constructors[dim]($nmethods)",
        title_style="bold underline yellow",
        width=width
    )

    # methods using type
    if length(info.methods) > 0
        methods = do_by_line(style_method_line, info.methods)
        nmethods = length(split_lines(methods)) > 1 ? Int(length(split_lines(methods))/2) : 1
    else
        methods = "[dim]No methods          [/dim]"
        nmethods = 0
    end

    methods_panel = TextBox(
        methods,
        title="Methods[dim]($nmethods)",
        title_style="bold underline yellow",
        width=width
    )


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


"""
useful:
    https://docs.julialang.org/en/v1/base/base/#Reflection
    https://docs.julialang.org/en/v1/stdlib/InteractiveUtils/?

print(functionloc(inspect, (DataType, Int)))

print(Base.@locals())

"""

@info "STARTING"
print(RenderableText("[bold bright_yellow]inspect([/]Test[bold bright_yellow])"))
print("\n\n")
for width in (140, 200)
    inspect(Panel, width) 
end
# println(" " * "."^200 * " ")

# @time TypeInfo(Panel);
# @time inspect(Panel)
# @time inspect(Panel)