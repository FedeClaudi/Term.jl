import Term: make_logo, @with_repr, termshow

@testset "logo" begin
    @test_nothrow make_logo()

    logo = make_logo()
    @test logo.measure.w == 84
    @test logo.measure.h == 28
end

@testset "REPR" begin
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

    struct Engine
        id::Int
        throttle::Vector
    end
    E = Engine(1, [1, 2, 3])
    @test sprint(termshow, E) ==
          "\e[38;2;155;179;224m╭──────────────────────────────────────╮\e[39m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m            \e[1m\e[38;2;224;219;121mid\e[22m\e[39m\e[38;2;187;134;219m::Int64\e[39m\e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m \e[38;2;179;212;255m1\e[39m              \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[0m\e[38;2;155;179;224m│\e[39m\e[0m     \e[1m\e[38;2;224;219;121mthrottle\e[22m\e[39m\e[38;2;187;134;219m::Vector\e[39m\e[2m\e[38;2;126;157;217m│\e[22m\e[39m\e[0m \e[38;2;179;212;255m[1, 2, 3]\e[39m      \e[0m\e[38;2;155;179;224m│\e[39m\e[0m\n\e[38;2;155;179;224m╰─────────────────────────── \e[38;2;227;172;141mEngine\e[39m\e[38;2;155;179;224m\e[38;2;155;179;224m ───╯\e[39m\e[0m\e[39m\e[38;2;155;179;224m\e[0m\n"
end
