# import Term: install_term_logger

# install_term_logger()

# println("\nTesting logging, stdout temporarily disabled")
# @suppress_out begin
#     @testset "\e[34mLOGS test" begin
#         @test_nowarn @info "my log!"

#         @test_nowarn @warn "tell us if this was [bold red]undexpected![/bold red]"

#         x = collect(1:2:20)
#         y = x * x'
#         name = "the name is [bold blue]Term[/bold blue]"
#         p1 = Panel("text")

#         @test_nowarn @error "[italic green bold]fancy logs![/italic green bold]" x y name √9 install_term_logger p1

#         @test_nowarn @info """asdada asdasd\nasdada;
#         asdadaada
#         asdadaxc

#         sdfs
#         s""" 1 + 2
#     end
# end
