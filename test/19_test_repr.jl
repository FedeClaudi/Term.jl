install_term_repr()
import Term.Consoles: clear
import Term: default_width


sprint_termshow(io::IO, x) = termshow(io, x; width = 60)


@testset "REPR renderable repr" begin
    p = string(Panel())
    w = TEST_CONSOLE_WIDTH
    @test sprint(show, Panel()) ==
    "\e[38;5;117mPanel <: AbstractRenderable\e[0m \e[2m(h:3, w:80)\e[0m"
end

@testset "REPR @with_repr" begin
    # just check that creating a @with_repr is ok
    @with_repr struct Rocket
        width::Int
        height::Int
        mass::Float64

        manufacturer::String
    end

    obj = Rocket(10, 50, 5000, "NASA")

    io = IOBuffer()
    show(IOContext(io), "text/plain", obj)
    s = String(take!(io))
    
    correct_s = compare_to_string(s, "termshow_panel")
    @test s == correct_s
    @test sprint(termshow, obj) == correct_s

    termshow(devnull, Rocket)  # coverage

    @with_repr struct T end
    @test sprint(termshow, T()) ==
    "\e[38;2;155;179;224m╭──────────╮\e[39m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m  T()\e[38;2;187;134;219m::T\e[39m  \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[38;2;155;179;224m╰──── \e[38;2;227;172;141mT\e[39m\e[38;2;155;179;224m\e[38;2;155;179;224m ───╯\e[39m\e[0m\e[39m\e[38;2;155;179;224m\e[0m\n"
end

@testset "REPR @with_repr with doc" begin
    # just check that creating a @with_repr is ok

        """docs"""
    @with_repr  struct Rocket2
            width::Int
            height::Int
            mass::Float64

            manufacturer::String
    end
end

objs = if VERSION >= v"1.7.1"
    (
        (1, [1, 2, 3]),
        (2, Dict(:x => [1, 2, 3], "a" => Dict(:z => "a"))),
        (3, Dict(i => i for i in 1:100)),
        (4, zeros(120, 300)),
        (5, zeros(200)),
        (6, zeros(3, 3, 3)),
        (7, clear),
        (8, :(x / y + √9)),
    )
else
    (
        (1, [1, 2, 3]),
        (2, Dict(:x => [1, 2, 3], "a" => Dict(:z => "a"))),
        (3, Dict(i => i for i in 1:100)),
        (7, clear),
    )
end

@testset "TERMSHOW for types" begin
    for (i, t) in objs
        t = sprint(sprint_termshow, t)
        compare_to_string(t, "termshow_$i")
    end
end

@testset "Term automatic repr" begin
    repr_show(io, x) = show(io, MIME("text/plain"), x)
    @test sprint(repr_show, 1) == "\e[38;2;144;202;249m1\e[39m"
    
    compare_to_string(sprint(repr_show, Dict(1 => :x)), "automatic_repr_1")
    compare_to_string(sprint(repr_show, :(x + y)), "automatic_repr_2")
end
