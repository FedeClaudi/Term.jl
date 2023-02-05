using Term

install_term_logger()



struct MyStruct
    x::String
    y::Vector
    z::Int
end


@info MyStruct("aa a"^100, zeros(200), 4)   Dict(:z=>zeros(50)) 1 x .+ 2

# @info zeros(20)



