install_term_repr()
import Term.Consoles: clear
import Term: default_width

@testset "REPR renderable repr" begin
    p = string(Panel())
    w = default_width()
    @test sprint(show, Panel()) ==
          "\e[38;5;117mPanel <: AbstractRenderable\e[0m \e[2m(h:2, w:$w)\e[0m"
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

    correct_s = "\e[38;2;155;179;224m╭──────────────────────────────────────╮\e[39m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m             \e[1m\e[38;2;224;219;121mwidth\e[22m\e[39m\e[38;2;187;134;219m::Int64\e[39m\e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m \e[38;2;179;212;255m10\e[39m         \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m            \e[1m\e[38;2;224;219;121mheight\e[22m\e[39m\e[38;2;187;134;219m::Int64\e[39m\e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m \e[38;2;179;212;255m50\e[39m         \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m            \e[1m\e[38;2;224;219;121mmass\e[22m\e[39m\e[38;2;187;134;219m::Float64\e[39m\e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m \e[38;2;179;212;255m5000.0\e[39m     \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m     \e[1m\e[38;2;224;219;121mmanufacturer\e[22m\e[39m\e[38;2;187;134;219m::String\e[39m\e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m \e[38;2;179;212;255mNASA\e[39m       \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[38;2;155;179;224m╰─────────────────────────── \e[38;2;227;172;141mRocket\e[39m\e[38;2;155;179;224m\e[38;2;155;179;224m ───╯\e[39m\e[0m\e[39m\e[38;2;155;179;224m\e[0m\n"
    @test s == correct_s
    @test sprint(termshow, obj) == correct_s

    termshow(devnull, Rocket)  # coverage

    @with_repr struct T end

    @test sprint(termshow, T()) ==
          "\e[38;2;155;179;224m╭──────────────────────────────────────╮\e[39m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m                T()\e[38;2;187;134;219m::T\e[39m                \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[38;2;155;179;224m╰──────────────────────────────── \e[38;2;227;172;141mT\e[39m\e[38;2;155;179;224m\e[38;2;155;179;224m ───╯\e[39m\e[0m\e[39m\e[38;2;155;179;224m\e[0m\n"
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

# ! Save to text file for later comparison
sprint_termshow(io::IO, x) = termshow(io, x; width = 60)
for (i, t) in objs
    t = sprint(sprint_termshow, t)
    tofile(string(t), "./txtfiles/termshow_$i.txt")
    # termshow(t; width=60)
end

@testset "TERMSHOW for types" begin
    for (i, t) in objs
        t = sprint(sprint_termshow, t)
        @test fromfile("./txtfiles/termshow_$i.txt") == t
    end
end

@testset "Term automatic repr" begin
    repr_show(io, x) = show(io, MIME("text/plain"), x)
    @test sprint(repr_show, 1) == "\e[38;2;144;202;249m1\e[39m"

    @test sprint(repr_show, Dict(1 => :x)) ==
          "\e[38;2;155;179;224m╭──── \e[38;2;227;172;141mDict {Int64, Symbol} \e[39m\e[38;2;155;179;224m\e[38;2;155;179;224m ───────────╮\e[39m\e[0m\e[39m\e[38;2;155;179;224m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m                                      \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m    \e[2m\e[38;2;187;134;219m {Int64} \e[22m\e[39m\e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m \e[1m\e[38;2;224;219;121m1\e[22m\e[39m \e[1m\e[31m=>\e[22m\e[39m \e[1m\e[38;2;179;212;255mx\e[22m\e[39m \e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m\e[2m\e[38;2;187;134;219m {Symbol} \e[22m\e[39m     \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m                                      \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[38;2;155;179;224m╰─────────────────────────── \e[1m\e[37m1\e[22m\e[39m\e[22m item\e[22m\e[39m\e[38;2;155;179;224m ───╯\e[39m\e[0m\e[39m\e[0m\n"

    @test sprint(repr_show, :(x + y)) ==
          "\e[38;2;155;179;224m╭──────────────────────────────────────╮\e[39m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m                \e[32mx \e[38;2;239;83;80m+\e[39m\e[32m y\e[39m                 \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m    \e[22m─────────────────────────────\e[0m\e[22m     \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m    \e[1m\e[38;2;224;219;121mhead\e[22m\e[39m\e[38;2;187;134;219m::Symbol\e[39m\e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m \e[38;2;179;212;255mcall\e[39m                \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m    \e[1m\e[38;2;224;219;121margs\e[22m\e[39m\e[38;2;187;134;219m::Vector\e[39m\e[38;2;187;134;219m\e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m \e[38;2;179;212;255mAny[:+, :x, :y]\e[39m     \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[38;2;155;179;224m╰───────────────────────────── \e[38;2;227;172;141mExpr\e[39m\e[38;2;155;179;224m\e[38;2;155;179;224m ───╯\e[39m\e[0m\e[39m\e[38;2;155;179;224m\e[0m\n"
end
