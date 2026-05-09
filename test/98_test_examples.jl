@testset "\e[34mEXAMPLES" begin
    println("\nTesting examples, stdout temporarily disabled")
    @suppress_out begin
        include("../examples/custom_repr.jl")
        include("../examples/dendogram.jl")
        include("../examples/markdown_rendering.jl")
        include("../examples/tree.jl")
        include("../examples/tables.jl")
        include("../examples/text_panel.jl")
        include("../examples/text_style.jl")
    end
end

@testset "\e[34mREADME" begin
    IS_WIN || @compare_to_string(include("../README.jl"), "README")
end
