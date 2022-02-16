module renderables

    export AbstractRenderable

    abstract type AbstractRenderable end

    function Base.show(io::IO, renderable::AbstractRenderable)
        if io == stdout 
            for seg in renderable.segments.segments
                println(io, seg)
            end
        else
            print(io, "$(typeof(renderable)) <: AbstractRenderable \e[2m(size: $(renderable.measure))\e[0m")
        end
    end

end