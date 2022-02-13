using InteractiveUtils


"""
    info(object::Any)

Prints information about an object and its type
"""
function info(obj)
    get(n) = escape_brackets(string(getproperty(obj, n)); replace_singles=true)
    values = [get(field) for field in fieldnames(typeof(obj))]

    info(typeof(obj); values=values)
end

"""
    info(object::DataType)

Prints information (docstring, fields...) for a `Type`
"""
function info(obj::DataType; values=nothing)
    width = 88

    # get metadata
    super = supertypes(obj)
    sub = subtypes(obj)
    sub = length(sub)>0 ? sub : "None"

    field_names = fieldnames(obj)
    field_types = obj.types
    values = isnothing(values) ? ["" for f in field_types] : values

    # prepare a string with the fields
    lines = []
    for (name, type, value) in zip(field_names, field_types, values)
        push!(lines, "  [cyan bold]$name[/cyan bold][gray70]{$type}[/gray70]: [yellow bold]$(string(value))[/yellow bold]   ($(typeof(value)))")
    end

    # make panels
    hierarchy = Panel("""
            [cyan]supertypes[/cyan]: $(super)
            [cyan]subtypes[/cyan]: $(sub)
        """;
        title="Types Hierarchy",
        title_style="white",
        style="blue",
        width = width,
    )

    fields = Panel(
        merge_lines(lines);
        title="Fields",
        style="blue",
        title_style="white",
        width=width,
    )

    # print
    tprint(
        Panel(
            Empty,
            "[bold green]Docstring[/bold green]:\n" * string(@doc obj),
            Separator(width+2; style="yellow"),
            hierarchy, fields;
            title="DataType: " * string(obj),
            style="bold yellow"
        )
    )
end
