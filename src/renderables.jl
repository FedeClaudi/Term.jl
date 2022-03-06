module renderables

    import ..measure: Measure    
    import ..segment: Segment
    import Term: split_lines, reshape_text, do_by_line


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

    """
    Creates a string representation of a renderable
    """
    function Base.string(r::AbstractRenderable)::String
        lines = [seg.text for seg in r.segments]
        return join(lines, "\n")
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
    Renderable(str::Union{Vector, AbstractString}; width::Union{Nothing, Int, Symbol}=nothing) =  RenderableText(str; width=width)
    Renderable(ren::AbstractRenderable; width::Union{Nothing, Int, Symbol}=nothing) = ren  # returns the renderable
    Renderable(segment::Segment; width::Union{Nothing, Int, Symbol}=nothing) = Renderable([segment], Measure([segment]))

    # ---------------------------------------------------------------------------- #
    #                                TEXT RENDERABLE                               #
    # ---------------------------------------------------------------------------- #
    mutable struct RenderableText <: AbstractRenderable
        segments::Vector
        measure::Measure
        text::AbstractString
    end

    function RenderableText(text::AbstractString; width::Union{Nothing, Int, Symbol}=nothing)
        # @info "creating RenderableText"  text width
        if width isa Number
            text = do_by_line((ln)->reshape_text(ln, width), text)
        end

        segments = [Segment(line) for line in split_lines(text)]
        return RenderableText(segments, Measure(segments), text)
    end

    RenderableText(text::Vector{AbstractString}; width::Union{Nothing, Int, Symbol}=nothing) = RenderableText(join(text, "\n"); width=width)
    RenderableText(text::Vector; width::Union{Nothing, Int, Symbol}=nothing) = RenderableText(join(text, "\n"); width=width)

    function RenderableText(text::AbstractString, style::AbstractString; width::Union{Nothing, Int, Symbol}=nothing)
        if width isa Number
            text = do_by_line((ln)->reshape_text(ln, width), text)
        end
        segments = [Segment(line, style) for line in split_lines(text)]
        return RenderableText(segments, Measure(segments), text)
    end   

    # -------------------------------- union type -------------------------------- #
    RenderablesUnion = Union{AbstractString, AbstractRenderable, RenderableText}


end