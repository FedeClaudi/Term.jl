import Documenter.DocSystem: getdocs

"""
    get_docstring(obj)

Extract and style an object's docstring.
"""
function get_docstring(obj)
    # get doc and docstring
    doc = getdocs(obj)

    doc = length(doc) > 0 ? doc : nothing
    if isnothing(doc)
        docstring = "no docstring"
    else
        docstrings::Vector{String} = []
        for dc in doc
            dstring = escape_brackets(dc.text[1])
            file = "[dim]$(dc.data[:binding]): $(dc.data[:path]) at line $(dc.data[:linenumber])[/dim]"
            push!(docstrings, dstring * file * "\n")
        end
        # docstring = join_lines([escape_brackets(d.text[1])*"\n[dim bold]----------[/dim bold]" for d in doc])

        # style
        docstring = highlight(join_lines(docstrings))
        docstring = highlight(docstring, :docstring)
    end
    return doc, unescape_brackets(docstring)
end

"""
    style_super_types(info)::String

Style a vector of super types 
"""
function style_super_types(info)::String
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

"""
    style_sub_types(info)::String

Style a vector of sub types.
"""
function style_sub_types(info)::String
    if !isnothing(info.subtypes)
        subtypes = "  [dim](subtypes):[/dim] "
        for sub in info.subtypes
            name = split(string(sub), ".")[end]
            subtypes *= "[bold]$name[/bold] ~ "
        end
        subtypes = subtypes[1:(end - 3)]
    else
        subtypes = "  [dim](subtypes): no subtypes[/dim]"
    end
    return subtypes
end

"""
    style_method_line(method::AbstractString; trim::Bool=false)::String

Style a string with method info (name, args, path...)
"""
function style_method_line(method::AbstractString; trim::Bool = false)::String
    if length(method) == 0
        return method
    end

    method = trim ? method[4:end] : method

    def, file = split(method, " in ")
    name, args = split(def, "(")
    args = "(" * args
    file = split(file, " at ")[end]

    return highlight(name, :emphasis) *
           highlight(highlight(args), :emphasis_light) *
           "\n         [dim]$file[/dim]"
end
