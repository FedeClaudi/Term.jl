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

fn_col = TERM_THEME[].func

"""
    style_methods(methods::Union{Vector{Base.Method}, Base.MethodList}, tohighlight::AbstractString)

Create a `Renderable` with styled `Method` information for `inspect(::DataType)`
"""
function style_methods(
    methods::Union{Vector{Base.Method},Base.MethodList},
    tohighlight::AbstractString,
)
    mets = []
    prevmod = ""
    for (i, m) in enumerate(methods)
        _name = split(string(m), " in ")[1]
        code =
            (occursin(_name, string(m.name)) ? split(_name, string(m.name))[2] : _name) |>
            highlight_syntax

        code = "{dim}" * code * "{/dim}"
        code = replace(
            code,
            tohighlight => "{$pink_light default}$tohighlight{/$pink_light default}{dim}",
        )
        code = RenderableText(
            "     {$pink dim}($i){/$pink dim}  {$fn_col}$(m.name){/$fn_col}" * code,
        )
        info =
            string(m.module) != prevmod ?
            RenderableText(
                "{bright_blue}   ────── Methods in {$pink underline bold}$(m.module){/$pink underline bold} for {$pink}$tohighlight{/$pink} ──────{/bright_blue}",
            ) : nothing
        prevmod = string(m.module)

        dest = RenderableText(
            "{dim default italic}             → $(m.file):$(m.line){/dim default italic}",
        )

        content = isnothing(info) ? code / dest / "" : info / code / dest / ""

        push!(mets, content)
    end
    return mets
end
