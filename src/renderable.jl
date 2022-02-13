module renderable
    export AbstractRenderable, AbstractText


    abstract type AbstractRenderable end

    abstract type AbstractText <: AbstractRenderable end

end


