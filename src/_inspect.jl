import Documenter.DocSystem: getdocs

"""
Extracts and styles a docstring object
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
            push!(docstrings, dstring *  file * "\n")
        end
        # docstring = join_lines([escape_brackets(d.text[1])*"\n[dim bold]----------[/dim bold]" for d in doc])

        # style
        docstring = highlight(join_lines(docstrings), theme)
        docstring = highlight(docstring,  theme, :docstring)
    end
    return doc, unescape_brackets(docstring)
end


"""
Styles a vector of super types 
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
Styles a vector of sub types 
"""
function style_sub_types(info)::String
    if !isnothing(info.subtypes)
        subtypes = "  [dim](subtypes):[/dim] "
        for sub in info.subtypes
            name = split(string(sub), ".")[end]
            subtypes *= "[bold]$name[/bold] ~ "
        end
        subtypes = subtypes[1:end-3]
    else
        subtypes = "  [dim](subtypes): no subtypes[/dim]"
    end
    return subtypes
end


"""
Styles a string with method info (name, args, path...)
"""
function style_method_line(method::AbstractString; trim::Bool=false)::String
    if length(method) == 0
        return method
    end
    
    method = trim ? method[4:end] : method

    def, file = split(method, " in ")
    name, args = split(def, "(")
    args = "(" * args
    file = split(file, " at ")[end]

    return highlight(name, theme, :emphasis) *  highlight(highlight(args, theme), theme, :emphasis_light) * "\n         [dim]$file[/dim]"
end