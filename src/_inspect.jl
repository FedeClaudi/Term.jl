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
