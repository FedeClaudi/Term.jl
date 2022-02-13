module renderable
    include("utils.jl")

    export AbstractRenderable, AbstractText


    abstract type AbstractRenderable end

    abstract type AbstractText <: AbstractRenderable end
    abstract type AbstractPanel <: AbstractRenderable end

    function Base.show(io::IO, renderable::AbstractRenderable)
        print("($(typeof(renderable))): '$(strip_ansi(renderable.string))'")
    end

end


