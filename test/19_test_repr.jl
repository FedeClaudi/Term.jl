install_term_repr()
import Term.Consoles: clear
import Term: Panel

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
    @with_repr struct T end

    VERSION ≥ v"1.7" && begin
        IS_WIN || @compare_to_string sprint(termshow, obj) "repr_rocket"
        IS_WIN || @compare_to_string sprint(termshow, Rocket) "repr_rocket_struct"
        IS_WIN || @compare_to_string sprint(termshow, T()) "repr_T_struct"
    end

    @with_repr struct MyTestStruct3
        x::String
        y::Array
        z::Int
        a::Panel
        c::String
    end

    mts = MyTestStruct3("aa aa"^100, zeros(100, 100), 3, Panel(), "b b b"^100)

    VERSION ≥ v"1.7" && begin
        IS_WIN || @compare_to_string sprint(termshow, mts) "mts_repr"
    end
end

@testset "REPR @with_repr with doc" begin
    """docs"""
    @with_repr struct Rocket2
        width::Int
        height::Int
        mass::Float64

        manufacturer::String
    end

    r = Rocket2(1, 1, 1.0, "me")
    _repr = sprint(io -> show(io, MIME("text/plain"), r))
    IS_WIN || @compare_to_string _repr "repr_rocket_2"
    IS_WIN ||
        @compare_to_string sprint(io -> show(io, MIME("text/plain"), Rocket2)) "repr_rocket_2_show"
end

"test function"
fn(x::Int) = x
fn(s::String) = s

objs = if VERSION >= v"1.7.1"
    (
        (1, [1, 2, 3]),
        (2, Dict(:x => [1, 2, 3], "a" => Dict(:z => "a"))),
        (3, Dict(i => i for i in 1:100)),
        (4, zeros(120, 300)),
        (5, zeros(200)),
        (6, zeros(3, 3, 3)),
        (7, fn),
        (8, :(x / y + √9)),
        (9, zeros(10)),
        (10, zeros(5, 5)),
        (11, zeros(100, 100, 100)),
    )
else
    (
        (1, [1, 2, 3]),
        (2, Dict(:x => [1, 2, 3], "a" => Dict(:z => "a"))),
        (3, Dict(i => i for i in 1:100)),
        (7, fn),
    )
end

@testset "TERMSHOW for types" begin
    for (i, t) in objs
        t = sprint(sprint_termshow, t)
        IS_WIN || @compare_to_string(t, "termshow_$i")
    end
end

@testset "Term automatic repr" begin
    repr_show(io, x) = show(io, MIME("text/plain"), x)
    @test sprint(repr_show, 1) == "\e[38;2;144;202;249m1\e[39m"

    IS_WIN || @compare_to_string(sprint(repr_show, Dict(1 => :x)), "automatic_repr_1")
    IS_WIN || @compare_to_string(sprint(repr_show, :(x + y)), "automatic_repr_2")
end

@testset "@showme" begin
    # fix for different path on remote CI
    loc = "\e[2m/Users/federicoclaudi/Documents/Github/Term.jl/src/"
    rem = "             \e[2m/home/runner/work/Term.jl/Term.jl/src/"
    fn(x) = replace(x, rem => loc)

    IS_WIN || begin
        @compare_to_string(
            :(@showme tprint(stdout, "test")),
            "automatic_repr_showme_1",
            fn,
            2,  # skip the last two lines
        )
    end
end
