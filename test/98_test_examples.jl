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

false && @testset "\e[34mREADME" begin  # FIXME : comparison fails, because of console width
    @suppress_out begin
        include("../README.jl")
    end
    IS_WIN || @compare_to_string(main(), "README")
end
