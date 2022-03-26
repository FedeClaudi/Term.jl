
@testset "\e[34mEXAMPLES" begin
    println("\nTesting examples, stdout temporarily disabled")
    @suppress_out begin
        # @test_nothrow include("../examples/layout.jl")

        # @test_nothrow include("../examples/inspect.jl")
        include("../examples/inspect.jl")
        # @test_nothrow include("../examples/logging.jl")
        include("../examples/logging.jl")
        # @test_nothrow include("../examples/progressbars.jl")
        include("../examples/progressbars.jl")
        # @test_nothrow include("../examples/text_box.jl")
        include("../examples/text_box.jl")
        # @test_nothrow include("../examples/text_panel.jl")
        include("../examples/text_panel.jl")
        # @test_nothrow include("../examples/text_style.jl")
        include("../examples/text_style.jl")
        # @test_nothrow include("../examples/tree.jl")
        include("../examples/tree.jl")
    end
end