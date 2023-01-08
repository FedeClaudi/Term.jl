modules(m::Module) = ccall(:jl_module_usings, Any, (Any,), m)

"""
Write some function to define all functions and types in a module an submodules.
    And a "search" function
"""

using Term
import Term: highlight, highlight_syntax
# import Base.Docs: doc as getdocs
import Term.Links: Link

import Base.Docs: Binding, getdoc, meta, resolve

obj = Panel
mod = parentmodule(obj)
_methods = methods(obj)

binding = Binding(mod, Symbol(obj))

dict = meta(mod)
# if haskey(dict, binding)
multidoc = dict[binding]

for m in _methods
    println("\n\n\n")
    print(hLine(; style = "red"))
    println(m)
    sig = m.sig.types
    length(sig) == 1 && continue

    sig = if length(sig) == Tuple{}
    else
        Tuple{sig[2:end]...}
    end
    println(sig)
    try
        tprintln(multidoc.docs[sig].text[1])
    catch
        continue
    end
    # length() == 1 && continue
    # for msig in multidoc.order
    #     sig <: msig && println(multidoc.docs[msig])
    # end
end

#     println(multidoc)
# end

# """
# Get the docstring for a specific method disgnature. 
# """
# function get_method_docstring(obj::DataType, m::Method)    
#     ns = length(m.sig.types)
#     sig = if ns == 1 
#         return nothing
#     elseif ns == 1
#         Tuple{m.sig.types[1]}
#     else
#         Tuple{m.sig.types[2:end]...}
#     end

#     try
#         return getdocs(obj, sig)
#     catch
#         return nothing
#     end
# end

# function render_method(m::Method)
#     sig, m = split(string(m), " in ")
#     modul, file = split(m, " at ")
#     path, line = split(file, ":")
#     source = Link(string(path), parse(Int64, line); style="underline dim")

#     return highlight_syntax(sig) / modul / source
# end

# _methods = methods(Panel)
# docs = get_method_docstring.(Panel, _methods)

# print("\n"^50)
# for (m, d) in zip(_methods, docs)
#     println(render_method(m))
#     tprintln(d)

# end
