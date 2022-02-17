module renderables

    import ..measure: Measure    
    import ..segment: Segment
    

    export AbstractRenderable, Renderable, RenderableText

    # ------------------------------- abstract type ------------------------------ #
    abstract type AbstractRenderable end

    Measure(renderable::AbstractRenderable) = renderable.measure

   """
    Base.:+(r1::Union{AbstractString, AstractRenderable}, r2::Union{AbstractString, AstractRenderable})

    Concatenates two abstract rendereables
    """
    function Base.:+(r1::Union{AbstractString, AbstractRenderable}, r2::Union{AbstractString, AbstractRenderable})
        r1 = Renderable(r1)
        r2 = Renderable(r2)
        segments = vcat(r1.segments, r2.segments)
        return Renderable(
            segments,
            Measure(segments),
        )
    end


    function Base.show(io::IO, renderable::AbstractRenderable)
    if io == stdout 
        for seg in renderable.segments
            println(io, seg)
        end
    else
        print(io, "$(typeof(renderable)) <: AbstractRenderable \e[2m(size: $(renderable.measure))\e[0m")
    end
    end

    # ------------------------- generic renderable object ------------------------ #
    mutable struct Renderable <: AbstractRenderable
        segments::Vector
        measure::Measure
    end

    Renderable() = Renderable([], Measure(0, 0))
    Renderable(str::AbstractString) = RenderableText(str)
    Renderable(ren::AbstractRenderable) = ren  # returns the renderable
    Renderable(segment::Segment) = Renderable([segment], Measure([segment]))


    # ----------------------------- text rendererable ---------------------------- #
    mutable struct RenderableText <: AbstractRenderable
        segments::Vector
        measure::Measure
        text::AbstractString
    end

    function RenderableText(text::AbstractString)
        segments = [Segment(line) for line in split(text, "\n")]
        return RenderableText(segments, Measure(segments), text)
    end

    RenderableText(text::Vector{AbstractString}) = RenderableText(join(text, "\n"))

    function RenderableText(text::AbstractString, style::AbstractString)
        segments = [Segment(line, style) for line in split(text, "\n")]
        return RenderableText(segments, Measure(segments), text)
    end   

    # -------------------------------- union type -------------------------------- #
    RenderablesUnion = Union{AbstractString, AbstractRenderable, RenderableText}


end