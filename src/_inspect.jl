import Base.Docs: doc as getdocs
using Base.Docs: meta, Binding
import Markdown

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
    get_methods_with_docstrings(obj::Union{Union, DataType, Function})

Get the docstring for each method for an object (function/datatype).
"""
function get_methods_with_docstrings(
    obj::Union{Union,DataType,Function},
)::Tuple{Vector,Vector}
    # get the parent module and the methods list for the object
    mod = parentmodule(obj)
    mm = methods(obj)

    # get the module's multidoc
    binding = Binding(mod, Symbol(obj))
    dict = meta(mod)
    multidoc = dict[binding]

    # for each module, attempt to get the docstring as markdown
    docstrings = []
    for m in mm
        # cleanup signature
        sig = length(m.sig.types) == 1 ? Tuple{} : Tuple{m.sig.types[2:end]...}

        haskey(multidoc.docs, sig) || begin
            push!(docstrings, nothing)
            continue
        end
        docs = multidoc.docs[sig].text[1] |> Markdown.parse
        push!(docstrings, docs)
    end

    return mm, docstrings
end
