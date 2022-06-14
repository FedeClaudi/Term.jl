import Base.Docs: doc as getdocs

"""
    get_docstring(obj)

Extract and style an object's docstring.
"""
function get_docstring(obj)
    # get doc and docstring
    doc = getdocs(obj)

    docstring = if isnothing(doc)
        "no docstring"
    else
        highlight(highlight(doc), :docstring)
    end
    return doc, unescape_brackets(docstring)
end

"""
    style_super_types(info)::String

Style a vector of super types 
"""
function style_super_types(info)::String
    return if isnothing(info.supertypes)
        "{dim}(supertypes): no super types{/dim}"
    else
        st = "{dim}(supertypes):{/dim} {bold blue}$(info.name){/bold blue}"
        for sup in info.supertypes[2:end]
            abstract = isabstracttype(sup) ? "underline" : ""
            name = split(string(sup), ".")[end]
            st *= "{blue} <{/blue} {bold $abstract}$name{/bold $abstract}"
        end
        st
    end
end

"""
    style_sub_types(info)::String

Style a vector of sub types.
"""
function style_sub_types(info)::String
    return if isnothing(info.subtypes)
        "  {dim}(subtypes): no subtypes{/dim}"
    else
        st = "  {dim}(subtypes):{/dim} "
        for sub in info.subtypes
            name = split(string(sub), ".")[end]
            st *= "{bold}$name{/bold} ~ "
        end
        st[1:(end - 3)]
    end
end
