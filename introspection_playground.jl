using Revise
Revise.revise()
import Documenter.DocSystem: getdocs
using Term
import Term: Panel, TextBox, Spacer, hLine, hstack, split_lines, join_lines, do_by_line, RenderableText


abstract type AA end

abstract type AbstractTest <: AA end

"""
    Test

A test `struct` for inspection

More info

And more
"""
mutable struct Test <: AbstractTest
    x::Int
    y::String
end


Test(x) = Test(x[1], x[2])

my_test_method(x::Test) = print(x)
my_other_test_method(x::Test) = x/2

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

    @info "Building type info"

    return TypeInfo(string(type), super, sub, fields, constructors, _methods, doc)
end




function style_super_types(info::TypeInfo)::String
    if !isnothing(info.supertypes)
        stypes = "[dim](supertypes):[/] [bold blue]$(info.name)[/]"
        for sup in info.supertypes[2:end]
            abstract = isabstracttype(sup) ? "underline" : ""
            name = split(string(sup), ".")[end]
            stypes = stypes * "[blue] <[/blue] [bold $abstract]$name[/]"
        end
    else
        stypes = "[dim](supertypes): no super types[/]"
    end
    return stypes
end


function style_sub_types(info::TypeInfo)::String
    if !isnothing(info.subtypes)
        subtypes = "  [dim](subtypes):[/] "
        for sub in info.subtypes
            name = split(string(sub), ".")[end]
            subtypes *= "[bold]$name[/]"
        end
        subtypes = subtypes * " [blue]> [/blue][bold blue]$(info.name)[/]"
    else
        subtypes = "  [dim](subtypes): no subtypes[/]"
    end
    return subtypes
end


function style_method_line(method::AbstractString)
    if length(method) == 0
        return method
    end
    name = split(method[4:end], " in ")[1]
    rest = split(method, name)[end]

    text, file = split(rest, "at")
    _in, _module = split(text)
    method = "[bold blue]$name[/] in [bold italic]$_module[/]\n[dim]    $file"

    return method
end



function inspect(type::DataType, width=150)
    info = TypeInfo(type)


    # make textbox showing types hierarchy
    hierarchy = TextBox(
        "",
        style_super_types(info),
        "",
        style_sub_types(info),
        width=width, 
        title="Types hierarchy", 
        title_style="bold blue underline"
    )

    docs = TextBox(
        info.docs.text[1],
        title="Docstring",
        title_style="bold underline",
        width = (Int ∘ round)(width/4*3 - 4)

    )


    # panel showing type's field
    formatted_fields::Vector{AbstractString} = []
    if !isnothing(info.fields)
        for (name, type) in zip(info.fields["names"], info.fields["types"])
            push!(
                formatted_fields,
                "[bold yellow]$(string(name))[/][blue]::$(type)"
            )
        end
    end



    fields_panel = Panel(
        isnothing(formatted_fields) ? "[dim]No arguments[/]" : formatted_fields,
        title="Arguments", 
        title_style="bold yellow",
        style="dim yellow",
        height = max(docs.measure.h, length(formatted_fields)),
        width = (Int ∘ round)(width/4),
    )
    insights_panel = fields_panel * Spacer(4, fields_panel.measure.h) * docs

    # type's constructors
    constructors = do_by_line(style_method_line, info.constructors)
    nmethods = length(split_lines(constructors)) > 1 ? Int(length(split_lines(constructors))/2) : 1
    constructors = nmethods > 1 ? constructors : "[dim]No constructors          [/]"
    cosntructors_panel = TextBox(
        constructors,
        title="Constructors[dim](0)",
        title_style="bold underline",
        width=width
    )

    # methods using type
    if length(info.methods) > 0
        methods = do_by_line(style_method_line, info.methods)
        nmethods = length(split_lines(methods)) > 1 ? Int(length(split_lines(methods))/2) : 1
    else
        methods = "[dim]No methods          [/]"
        nmethods = 0
    end

    methods_panel = TextBox(
        methods,
        title="Metohods[dim]($nmethods)",
        title_style="bold underline",
        width=width
    )


    _title = isabstracttype(type) ? " [dim](Abstract)[/]" : ""
    println(
        Panel(
            Spacer(width, 1),
            hierarchy,
            hLine(width, "blue dim"),
            insights_panel,
            hLine(width, "blue dim"),
            cosntructors_panel,
            hLine(width, "blue dim"),
            methods_panel,
            title="$(typeof(type)): [bold]$(info.name)" * _title, 
            title_style="red",
            style="blue dim",
        )
    )

end

# TODO style docstring
# TODO style argument names
# TODO style constructors methods (first word colored, then highlight types in definition)

#! BUG: panel should rehsape things that are too wide

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
inspect(Panel)


# @time TypeInfo(Panel);
# @time inspect(Panel)
# @time inspect(Panel)