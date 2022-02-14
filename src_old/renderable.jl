module renderable
    include("utils.jl")

    using Parameters

    export AbstractRenderable, AbstractText
    export Line, Space, Empty

    # ---------------------------------------------------------------------------- #
    #                                Abstract types                                #
    # ---------------------------------------------------------------------------- #
    abstract type AbstractRenderable end

    abstract type AbstractText <: AbstractRenderable end
    abstract type AbstractPanel <: AbstractRenderable end

    function Base.show(io::IO, renderable::AbstractRenderable)
        print("($(typeof(renderable))): '$(strip_ansi(renderable.string))'")
    end

    # renderables concatenation
    function Base.:+(r1::Union{AbstractString, AbstractRenderable}, r2::Union{AbstractString, AbstractRenderable})::Renderable
        s1 = lines(r1; discard_empty=false)
        s2 = lines(r2; discard_empty=false)
        return Renderable(merge_lines(vcat(s1, s2)))
    end

    # repetition
    Base.:^(r::AbstractRenderable, n) = Renderable(r.string^n)

    # renderable-string concatenation
    Base.:*(r::AbstractRenderable, s::AbstractString)::Renderable = Renderable(r.string * s)
    Base.:*(s::AbstractString, r::AbstractRenderable)::Renderable = Renderable(s * r.string)

    # ---------------------------------------------------------------------------- #
    #                              General renderable                              #
    # ---------------------------------------------------------------------------- #
    """
    Stores a generic renderable as a string
    """
    struct Renderable <: AbstractRenderable
        string::String
    end

    # ---------------------------------------------------------------------------- #
    #                             Constant renderables                             #
    # ---------------------------------------------------------------------------- #
    @with_kw struct LINE <: AbstractRenderable
        string::AbstractString = "\n"
    end
    Line = LINE()

    @with_kw struct EMPTY <: AbstractRenderable
        string::AbstractString = ""
    end
    Empty = EMPTY()

    @with_kw struct SPACE <: AbstractRenderable
        string::AbstractString = " "
    end
    Space = SPACE()


end


