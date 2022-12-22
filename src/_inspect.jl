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
    style_methods(methods::Union{Vector{Base.Method}, Base.MethodList}, tohighlight::AbstractString)

Create a `Renderable` with styled `Method` information for `inspect(::DataType)`
"""
function style_methods(
    methods::Union{Vector{Base.Method},Base.MethodList},
    tohighlight::AbstractString;
    constructor::Bool = false,
)
    txt_col = TERM_THEME[].text
    fn_col = TERM_THEME[].func
    highlight_col = TERM_THEME[].inspect_highlight
    accent_col = TERM_THEME[].inspect_accent
    mets = []
    prevmod = ""
    for (i, m) in enumerate(methods)
        code = "    - " * split(string(m), " in ")[1] |> highlight_syntax
        code = replace(code, string(m.name) => "{$fn_col}$(m.name){/$fn_col}")

        info =
            string(m.module) != prevmod ?
            RenderableText(
                "{bright_blue}   ────── Methods in {$accent_col underline bold}$(m.module){/$accent_col underline bold} for {$accent_col}$tohighlight{/$accent_col} ──────{/bright_blue}",
            ) : nothing
        prevmod = string(m.module)
        
        dest = RenderableText(
            "\e[0m{dim default italic}             → $(m.file):$(m.line){/dim default italic}",
        )
        content = isnothing(info) ? code / dest / "" : info / code / dest / ""
        push!(mets, content)
    end
    return mets
end
