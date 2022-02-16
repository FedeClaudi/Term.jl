module renderables

    import ..segment: Segments, Segment
    import ..measure: Measure

    export AbstractRenderable

    # ------------------------------- abstract type ------------------------------ #
    abstract type AbstractRenderable end


   RenderablesUnion = Union{Segment, Segments, AbstractString, AbstractRenderable}

    # ------------------------- generic renderable object ------------------------ #
    struct Renderable <: AbstractRenderable
        segments::Segments
        measure::Measure
    end

    Renderable(str::AbstractString) = Renderable(Segments(str), Measure(str))
    Renderable(ren::AbstractRenderable) = ren  # returns the renderable
    Renderable(segment::Segment) = Renderable(Segments(segment), segment.measure)
    Renderable(segments::Segments) = Renderable(segments, segments.measure)

    """
        Base.:+(r1::Union{AbstractString, AstractRenderable}, r2::Union{AbstractString, AstractRenderable})

    Concatenates two abstract rendereables
    """
    function Base.:+(r1::Union{AbstractString, AbstractRenderable}, r2::Union{AbstractString, AbstractRenderable})
        r1 = Renderable(r1)
        r2 = Renderable(r2)

        return Renderable(
            r1.segments + r2.segments,
            r1.measure + r2.measure
        )
    end


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