using Revise
Revise.revise()

using Term
import Term: Panel, TextBox, Spacer, hLine, hstack, split_lines, join_lines, do_by_line, RenderableText


abstract type AA end

abstract type AbstractTest <: AA end

"""
    Test

A test `struct` for inspection
"""
mutable struct Test <: AbstractTest
    x::Int
    y::String
end


Test(x) = Test(x[1], x[2])

my_test_method(x::Test) = print(x)
my_other_test_method(x::Test) = x/2


function extract_type_info(type::DataType)
    name = string(type)
    super = supertypes(type)
    super = length(super) > 0 ? super : nothing


    subs = subtypes(type)

    subs = length(subs) > 0 ? subs : nothing

    if !isabstracttype(type)
        fields = Dict(
            "names" => fieldnames(type),
            "types"=> fieldtypes(type),
        )
    else
        fields = nothing
    end

    type_methods = join_lines(split_lines(string(methods(type)))[2:end])

    using_type_methods = methodswith(type)
    if length(using_type_methods) > 0
        using_type_methods = join_lines([string(x) for x in using_type_methods])
    end

    doc = string(@doc type)

   return name, super, subs, fields, type_methods, doc, using_type_methods
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

function inspect(type::DataType, width=88)
    name, super, subs, fields, type_methods, doc, using_type_methods = extract_type_info(type)

    # make a string for supertypes/subtypes
    if !isnothing(super)
        stypes = "[dim](supertypes):[/] [bold blue]$name[/]"
        for sup in super[2:end]
            abstract = isabstracttype(sup) ? "underline" : ""
            stypes = stypes * "[blue] <[/blue] [bold $abstract]$sup[/]"
        end
    else
        stypes = "[dim](supertypes): no super types[/]"
    end

    if !isnothing(subs)
        subtypes = "  [dim](subtypes):[/] "
        for sub in subs
            subtypes *= "[bold]$sub[/]"
        end
        subtypes = subtypes * " [blue]> [/blue][bold blue]$name[/]"
    else
        subtypes = "  [dim](subtypes): no subtypes[/]"
    end

    # textbox showing types hierarchy
    hierarchy = TextBox(
        "",
        stypes,
        "",
        subtypes,
        width=120, title="Types hierarchy", title_style="bold blue underline"
    )

    # docstring
    docs = TextBox(
        " ",
        startswith(doc, "No documentation found.") ? "[bold salmon1]No documentation found." : doc,
        title="Docstring",
        title_style="bold underline",
        width = (Int ∘ round)(width/4*3 - 4)

    )


    # panel showing type's field
    formatted_fields::Vector{AbstractString} = []
    if !isnothing(fields)
        for (name, type) in zip(fields["names"], fields["types"])
            push!(
                formatted_fields,
                "[bold yellow]$(string(name))[/][blue]::$(type)"
            )
        end
    end

    fields_panel = Panel(
        isnothing(fields) ? "[dim]No arguments[/]" : formatted_fields,
        title="Arguments", 
        title_style="bold yellow",
        style="dim yellow",
        height = max(docs.measure.h, length(formatted_fields)),
        width = (Int ∘ round)(width/4),
    )
    insights_panel = hstack(fields_panel, Spacer(4, fields_panel.measure.h), docs)

    # type's methods
    type_methods = do_by_line(style_method_line, type_methods)
    nmethods = length(split_lines(type_methods)) > 1 ? Int(length(split_lines(type_methods))/2) : 1
    if nmethods > 1
        methods_panel = TextBox(
            type_methods,
            title="Constructors[dim]($nmethods)",
            title_style="bold underline",
            width=width
        )
    else
        methods_panel = TextBox(
            "[dim]No methods          [/]",
            title="Constructors[dim](0)",
            title_style="bold underline",
            width=width
        )
    end

    # methods using type
    if length(using_type_methods) > 0
        using_type_methods = do_by_line(style_method_line, using_type_methods)
        nmethods = length(split_lines(using_type_methods)) > 1 ? Int(length(split_lines(using_type_methods))/2) : 1
        using_methods_panel = TextBox(
            using_type_methods,
            title="Metohods[dim]($nmethods)",
            title_style="bold underline",
            width=width
        )
    else
        using_methods_panel = TextBox(
            "[dim]No methods          [/]",
            title="Metohods[dim](0)",
            title_style="bold underline",
            width=width
        )
    end

    _title = isabstracttype(type) ? " [dim](Abstract)[/]" : ""
    println(
        Panel(
            Spacer(width, 1),
            hierarchy,
            hLine(width, "blue dim"),
            insights_panel,
            hLine(width, "blue dim"),
            methods_panel,
            hLine(width, "blue dim"),
            using_methods_panel,
            title="$(typeof(type)): [bold]$name" * _title, 
            title_style="red",
            style="blue dim",
        )
    )

end


# TODO show methods - add methods using abstract supertypes
# TODO get docstring
# TODO get source code with @less


"""
useful:
    https://docs.julialang.org/en/v1/base/base/#Reflection
    https://docs.julialang.org/en/v1/stdlib/InteractiveUtils/?

print(functionloc(inspect, (DataType, Int)))

print(Base.@locals())

"""


print(RenderableText("[bold bright_yellow]inspect([/]Test[bold bright_yellow])"))
print("\n\n")
inspect(AbstractTest)
inspect(Test)
